unit SynAdapter;

interface

uses
  System.Win.Registry,
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
  HKEY = Cardinal;
  TBetterRegistry = TRegistry;

const
  HKEY_LOCAL_MACHINE = 1; // dummy for now
  HKEY_CURRENT_USER  = 2;

function StringToColor(const Str: string): TColor;
function SynWideUpperCase(const value: string): string;
function SynWideLowerCase(const value: string): string;

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

end.
