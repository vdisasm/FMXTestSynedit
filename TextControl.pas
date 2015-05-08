unit TextControl;

interface

uses
  System.Classes,
  System.Types,
  System.UITypes,
  System.SysUtils,
{$IFDEF DEBUG}
  System.Diagnostics,
{$ENDIF}
  FMX.Types,
  FMX.Graphics,
  FMX.Controls,
  FMX.StdCtrls,
  FMX.TextLayout,

  TextLineAbstraction,

  SynEditHighlighter;

type
  TVirtualTextControl = class(TControl)
  protected
    FLines: TTextLines;
    FTopLine: TLineIndex;
    FScrollStep: integer;
    FVScrollBar: TScrollBar;
    FVScrollBarChangedDisabled: Boolean;
    procedure VScrollBarChanged(Sender: TObject);
  protected
    FGutterWidth: single;
    FHighlighter: TSynCustomHighlighter;
    FBackgroundColor: TAlphaColor;
    FForegroundColor: TAlphaColor;
  private
    procedure SetHighlighter(const Value: TSynCustomHighlighter);
  protected
    procedure MouseWheel(Shift: TShiftState; WheelDelta: integer; var Handled: Boolean); override;
    procedure LinesChanged(Sender: TObject);
    procedure PaintLine(Canvas: TCanvas; LineIndex: TLineIndex; var Y: single);
    procedure PaintAll(Canvas: TCanvas);
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    // dy > 0: scroll down
    // dy < 0: scroll up
    procedure ScrollDelta(dy: integer);
    procedure ScrollToLine(Index: TLineIndex);

    property Lines: TTextLines read FLines;
    property Highlighter: TSynCustomHighlighter read FHighlighter write SetHighlighter;
  end;

implementation

const
  DEFAULT_SCROLL_STEP = 3;

{$IF DEFINED(MSWINDOWS)}
  DEFAULT_FONT_NAME = 'Consolas';
  DEFAULT_FONT_SIZE = 16;
{$ELSE IF DEFINED(ANDROID)}
  DEFAULT_FONT_NAME = 'Droid Sans Mono';
  DEFAULT_FONT_SIZE = 24;
{$ELSE MESSAGE FATAL 'NO FONT INFO'}
{$ENDIF}


constructor TVirtualTextControl.Create(AOwner: TComponent);
begin
  inherited;

  FLines := TTextLines.Create;
  FLines.OnChanged := LinesChanged;

  FScrollStep := DEFAULT_SCROLL_STEP;

  FVScrollBar := TScrollBar.Create(self);
  FVScrollBar.Orientation := TOrientation.Vertical;
  FVScrollBar.Parent := self;
  FVScrollBar.Align := TAlignLayout.Right;
  FVScrollBar.OnChange := VScrollBarChanged;

  FGutterWidth := 32;
  FBackgroundColor := TAlphaColorRec.White;
  FForegroundColor := TAlphaColorRec.Black;
end;

destructor TVirtualTextControl.Destroy;
begin
  FLines.Free;
  inherited;
end;

procedure TVirtualTextControl.LinesChanged(Sender: TObject);
begin
  FVScrollBar.Min := 0;
  FVScrollBar.Max := FLines.GetLineCount - 1;
end;

procedure TVirtualTextControl.MouseWheel(Shift: TShiftState; WheelDelta: integer; var Handled: Boolean);
begin
  inherited;
  if WheelDelta < 0 then
    ScrollDelta(FScrollStep)
  else if WheelDelta > 0 then
    ScrollDelta(-FScrollStep);
end;

procedure TVirtualTextControl.PaintLine(Canvas: TCanvas; LineIndex: TLineIndex; var Y: single);
var
  LineText: string;
  TokenPos: integer;
  TokenText: string;
  TokenAttr: TSynHighlighterAttributes;
  X: single;
  Rect: TRectF;
  HAlign: TTextAlign;
const
  VAlign = TTextAlign.Leading;
begin
  if LineIndex = 0 then
    if Assigned(FHighlighter) then
      FHighlighter.ResetRange;

  LineText := FLines.GetLine(LineIndex);
  if Assigned(FHighlighter) then
    FHighlighter.SetLine(LineText, LineIndex);

  X := FGutterWidth;
  while (not Assigned(FHighlighter)) or (not FHighlighter.GetEol) do
  begin
    if Assigned(FHighlighter) then
    begin
      // Get token info.
      TokenPos := FHighlighter.GetExpandedTokenPos;
      TokenText := FHighlighter.GetExpandedToken;
      TokenAttr := FHighlighter.GetTokenAttribute;
    end
    else
    begin
      TokenPos := 0;
      TokenText := LineText;
      TokenAttr := nil;
    end;

    // Set style to measure rect correctly.
    if Assigned(TokenAttr) then
      Canvas.Font.Style := TokenAttr.Style
    else
      Canvas.Font.Style := [];

    HAlign := TTextAlign.Leading;

    // Measure.
    Rect := RectF(X, Y, LocalRect.Width, LocalRect.Height);
    Canvas.MeasureText(Rect, TokenText, False, [], HAlign, VAlign);

    // Background.
    if Assigned(TokenAttr) and (TokenAttr.Background <> TAlphaColorRec.Null) then
    begin
      Canvas.Fill.Color := TokenAttr.Background;
      Canvas.FillRect(Rect, 2, 2, AllCorners, AbsoluteOpacity);
    end;

    // Foreground.
    if Assigned(TokenAttr) and (TokenAttr.Foreground <> TAlphaColorRec.Null) then
      Canvas.Fill.Color := TokenAttr.Foreground
    else
      Canvas.Fill.Color := FForegroundColor;

    Canvas.FillText(Rect, TokenText, False, AbsoluteOpacity, [], HAlign, VAlign);

    // Next X.
    X := X + Rect.Width;

    if Assigned(FHighlighter) then
      // Next token.
      FHighlighter.Next
    else
      break;
  end;

  // Next Y.
  Y := Y + Rect.Height;
end;

procedure TVirtualTextControl.PaintAll(Canvas: TCanvas);
var
  LineIndex: TLineIndex;
  LineCount: TLineIndex;
  LineText: string;
  Rect: TRectF;
  X, Y: single;
begin
  Rect := LocalRect;

  Canvas.Font.Family := DEFAULT_FONT_NAME;
  Canvas.Font.Size := DEFAULT_FONT_SIZE;

  // Clear text area.
  Canvas.Fill.Color := FBackgroundColor;
  Rect := RectF(FGutterWidth, Y, LocalRect.Width, LocalRect.Bottom);
  Canvas.FillRect(Rect, 0, 0, [], AbsoluteOpacity);

  // Gutter area.
  Rect := RectF(0, 0, FGutterWidth, LocalRect.Height);
  Canvas.Fill.Color := $FFF4F4F4;
  Canvas.FillRect(Rect, 0, 0, [], AbsoluteOpacity);

  LineIndex := FTopLine;
  LineCount := FLines.GetLineCount;

  Canvas.Fill.Color := TAlphaColorRec.Black;

  X := FGutterWidth;
  Y := 0;
  while (LineIndex < LineCount) and (Y < LocalRect.Bottom) do
  begin
    LineText := FLines.GetLine(LineIndex);
    Rect := RectF(X, Y, LocalRect.Right, LocalRect.Bottom);
    PaintLine(Canvas, LineIndex, Y);
    Inc(LineIndex);
  end;
end;

procedure TVirtualTextControl.Paint;
{$IFDEF DEBUG}
var
  StopWatch: TStopwatch;
{$ENDIF}
begin
  inherited;
{$IFDEF DEBUG}
  StopWatch := TStopwatch.StartNew;
{$ENDIF}
  PaintAll(Canvas);
{$IFDEF DEBUG}
  StopWatch.Stop;
  if IsConsole then
    Writeln('Paint took ', string(StopWatch.Elapsed));
{$ENDIF}
end;

procedure TVirtualTextControl.ScrollDelta(dy: integer);
var
  NewTopLine: TLineIndex;
begin
  // Update FTopLine
  if dy < 0 then
  begin
    if Abs(dy) > FTopLine then
      NewTopLine := 0
    else
      NewTopLine := FTopLine + dy;
  end
  else
  begin
    NewTopLine := FTopLine + dy;
    if NewTopLine >= FLines.GetLineCount() then
      NewTopLine := FLines.GetLineCount() - 1;
  end;

  ScrollToLine(NewTopLine);
end;

procedure TVirtualTextControl.ScrollToLine(Index: TLineIndex);
begin
  if Index <> FTopLine then
  begin
    FTopLine := Index;

    FVScrollBarChangedDisabled := True;
    FVScrollBar.Value := FTopLine;
    FVScrollBarChangedDisabled := False;

    InvalidateRect(LocalRect);
  end;
end;

procedure TVirtualTextControl.SetHighlighter(const Value: TSynCustomHighlighter);
begin
  FHighlighter := Value;
  InvalidateRect(LocalRect);
end;

procedure TVirtualTextControl.VScrollBarChanged(Sender: TObject);
begin
  if not FVScrollBarChangedDisabled then
  begin
    ScrollToLine(Trunc(TScrollBar(Sender).Value));
  end;
end;

initialization

GlobalUseGPUCanvas := True;

end.
