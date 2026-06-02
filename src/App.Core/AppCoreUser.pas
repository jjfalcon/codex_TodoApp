unit AppCoreUser;

interface

type
  TUserRole = (urAdmin, urNormal);

  TUser = class
  private
    FId: string;
    FUsername: string;
    FDisplayName: string;
    FPasswordHash: string;
    FSalt: string;
    FActive: Boolean;
    FRole: TUserRole;
    FFailedAttempts: Integer;
    FLocked: Boolean;
  public
    constructor Create(const AId, AUsername, ADisplayName, APasswordHash,
      ASalt: string; AActive: Boolean; ARole: TUserRole);

    property Id: string read FId;
    property Username: string read FUsername;
    property DisplayName: string read FDisplayName;
    property PasswordHash: string read FPasswordHash write FPasswordHash;
    property Salt: string read FSalt write FSalt;
    property Active: Boolean read FActive write FActive;
    property Role: TUserRole read FRole write FRole;
    property FailedAttempts: Integer read FFailedAttempts write FFailedAttempts;
    property Locked: Boolean read FLocked write FLocked;
  end;

implementation

constructor TUser.Create(const AId, AUsername, ADisplayName, APasswordHash,
  ASalt: string; AActive: Boolean; ARole: TUserRole);
begin
  inherited Create;
  FId := AId;
  FUsername := AUsername;
  FDisplayName := ADisplayName;
  FPasswordHash := APasswordHash;
  FSalt := ASalt;
  FActive := AActive;
  FRole := ARole;
  FFailedAttempts := 0;
  FLocked := False;
end;

end.
