unit AppCoreUser;

interface

type
  TUserRole = (urAdmin, urNormal);

  TUser = class
  private
    FId: string;
    FUsername: string;
    FDisplayName: string;
    FEmail: string;
    FPasswordHash: string;
    FSalt: string;
    FActive: Boolean;
    FDeleted: Boolean;
    FRole: TUserRole;
    FFailedAttempts: Integer;
    FLocked: Boolean;
    FCreatedAt: TDateTime;
    FLastLoginAt: TDateTime;
  public
    constructor Create(const AId, AUsername, ADisplayName, APasswordHash,
      ASalt: string; AActive: Boolean; ARole: TUserRole;
      const AEmail: string = ''; ACreatedAt: TDateTime = 0);

    property Id: string read FId;
    property Username: string read FUsername write FUsername;
    property DisplayName: string read FDisplayName write FDisplayName;
    property Email: string read FEmail write FEmail;
    property PasswordHash: string read FPasswordHash write FPasswordHash;
    property Salt: string read FSalt write FSalt;
    property Active: Boolean read FActive write FActive;
    property Deleted: Boolean read FDeleted write FDeleted;
    property Role: TUserRole read FRole write FRole;
    property FailedAttempts: Integer read FFailedAttempts write FFailedAttempts;
    property Locked: Boolean read FLocked write FLocked;
    property CreatedAt: TDateTime read FCreatedAt write FCreatedAt;
    property LastLoginAt: TDateTime read FLastLoginAt write FLastLoginAt;
  end;

implementation

constructor TUser.Create(const AId, AUsername, ADisplayName, APasswordHash,
  ASalt: string; AActive: Boolean; ARole: TUserRole; const AEmail: string;
  ACreatedAt: TDateTime);
begin
  inherited Create;
  FId := AId;
  FUsername := AUsername;
  FDisplayName := ADisplayName;
  FEmail := AEmail;
  FPasswordHash := APasswordHash;
  FSalt := ASalt;
  FActive := AActive;
  FDeleted := False;
  FRole := ARole;
  FFailedAttempts := 0;
  FLocked := False;
  FCreatedAt := ACreatedAt;
  FLastLoginAt := 0;
end;

end.
