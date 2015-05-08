unit Unit1;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,

  TextControl,
  SynHighlighterPas;

type
  TForm1 = class(TForm)
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
  private
  public
    tc: TVirtualTextControl;
    procedure DragOver(const Data: TDragObject; const Point: TPointF; var Operation: TDragOperation); override;
    procedure DragDrop(const Data: TDragObject; const Point: TPointF); override;
  end;

var
  Form1: TForm1;

implementation

{$R *.fmx}


procedure TForm1.DragDrop(const Data: TDragObject; const Point: TPointF);
begin
  inherited;
  if Length(Data.Files) > 0 then
    tc.lines.LoadFromFile(Data.Files[0]);
end;

procedure TForm1.DragOver(const Data: TDragObject; const Point: TPointF;
  var Operation: TDragOperation);
begin
  inherited;
  Operation := TDragOperation.Move;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  hlPas: TSynPasSyn;
begin
  if not assigned(tc) then
  begin
    tc := TVirtualTextControl.Create(self);
    tc.Align := TAlignLayout.Client;
    tc.Parent := self;

    hlPas := TSynPasSyn.Create(self);
    hlPas.SetDelphiColors;
    tc.Highlighter := hlPas;

    tc.lines.Text := hlPas.SampleSource;
  end;
end;

procedure TForm1.FormKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
begin
  case Key of
    vkEscape:
      Close;
    vkF11, vkF12:
      self.FullScreen := not self.FullScreen;
  end;
end;

end.
