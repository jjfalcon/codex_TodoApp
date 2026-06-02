unit AppCoreClock;

interface

type
  IClock = interface
    ['{B21B6BC1-2B78-4D56-A635-65187F89E42D}']
    function Now: TDateTime;
  end;

  TSystemClock = class(TInterfacedObject, IClock)
  public
    function Now: TDateTime;
  end;

implementation

uses
  SysUtils;

function TSystemClock.Now: TDateTime;
begin
  Result := SysUtils.Now;
end;

end.
