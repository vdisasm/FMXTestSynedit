unit TextLineAbstraction;

interface

uses
  System.Classes;

type
  TLineIndex = integer;

  TVirtualLines = class
  public
    // Abstracts
    function GetLineCount: TLineIndex; virtual; abstract;
    function GetLine(Index: TLineIndex): string; virtual; abstract;
  end;

  TTextLines = class(TVirtualLines)
  private
    FStrings: TStringList;
    procedure DoChanged;
    procedure SetText(const Value: string);
  public
    OnChanged: TNotifyEvent;

    constructor Create;
    destructor Destroy; override;

    function GetLineCount: TLineIndex; override;
    function GetLine(Index: TLineIndex): string; override;

    procedure LoadFromFile(const Path: string);

    property Text: string write SetText;
  end;

implementation

{ TTextLines }

constructor TTextLines.Create;
begin
  FStrings := TStringList.Create;
end;

destructor TTextLines.Destroy;
begin
  FStrings.Free;
  inherited;
end;

procedure TTextLines.DoChanged;
begin
  if Assigned(OnChanged) then
    OnChanged(Self);
end;

function TTextLines.GetLine(Index: TLineIndex): string;
begin
  Result := FStrings[Index];
end;

function TTextLines.GetLineCount: TLineIndex;
begin
  Result := FStrings.Count;
end;

procedure TTextLines.LoadFromFile(const Path: string);
begin
  FStrings.LoadFromFile(Path);
  DoChanged;
end;

procedure TTextLines.SetText(const Value: string);
begin
  FStrings.Text := Value;
  DoChanged;
end;

end.
