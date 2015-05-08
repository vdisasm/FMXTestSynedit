unit SynAdapter;

interface

uses
{$IFDEF MSWINDOWS}
  System.Win.Registry,
{$ENDIF}
  System.Types,
  System.UITypes,
  System.SysUtils;

const
  clWindow     = $FFFFFFFF; // todo: real color
  clWindowText = $FF808080; // todo: real color
  clYellow     = TAlphaColorRec.Yellow;

const
  // constants describing range of the Unicode Private Use Area (Unicode 3.2)
  PrivateUseLow  = WideChar($E000);
  PrivateUseHigh = WideChar($F8FF);
  // filler char: helper for painting wide glyphs
  FillerChar = PrivateUseLow;

type
  TSynString = string;

  HKEY = Cardinal;
{$IFDEF MSWINDOWS}
  TBetterRegistry = TRegistry;
{$ELSE}
  TBetterRegistry = class
  end;
{$ENDIF}

const
  HKEY_LOCAL_MACHINE = 1; // dummy for now
  HKEY_CURRENT_USER  = 2;

function StringToColor(const Str: string): TColor;
function SynWideUpperCase(const value: string): string;
function SynWideLowerCase(const value: string): string;
function DeleteTypePrefixAndSynSuffix(S: string): string;

implementation

function StringToColor(const Str: string): TColor;
begin
  result := 0;
end;

function SynWideUpperCase(const value: string): string;
begin
  result := value.ToUpper;
end;

function SynWideLowerCase(const value: string): string;
begin
  result := value.ToLower;
end;

function DeleteTypePrefixAndSynSuffix(S: string): string;
begin
  Result := S;
  if CharInSet(Result[1], ['T', 't']) then //ClassName is never empty so no AV possible
    if Pos('tsyn', LowerCase(Result)) = 1 then
      Delete(Result, 1, 4)
    else
      Delete(Result, 1, 1);

  if Copy(LowerCase(Result), Length(Result) - 2, 3) = 'syn' then
    SetLength(Result, Length(Result) - 3);
end;


end.
