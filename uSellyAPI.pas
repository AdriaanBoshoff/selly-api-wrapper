unit uSellyAPI;

interface

uses
  System.Types, System.Classes, System.SysUtils, System.Generics.Collections,
  IdHttp, IdSSLOpenSSL, IdHeaderList, IdCompressorZLib;

type
  TSellyData = record
    AsJson: string;
    Headers: TStringList;
    RateLimitRemaining: Integer;
    TotalPages: Integer;
  end;

type
  TSellyAPI = class
  private
    Email: string;
    Token: string;
    UserAgent: string;
    function GetData(const aURL_Path: string; const aPageIndex: Integer = 1): TSellyData;
  public
    function GetAllCoupons(const aPage: Integer = 1): TSellyData;
    function GetAllOrders(const aPage: Integer = 1): TSellyData;
    function GetAllProducts(const aPage: Integer = 1): TSellyData;
    function GetAllProductGroups(const aPage: Integer = 1): TSellyData;
    function GetAllQueries(const aPage: Integer = 1): TSellyData;
    function GetCoupon(const ID: string): TSellyData;
    function GetProduct(const ID: string): TSellyData;
    function GetProductGroup(const ID: string): TSellyData;
    function GetQuery(const ID: string): TSellyData;
    constructor Create(const aEmail, aToken: string; const aUseragent: string = 'SellyAPI/1.0');
  end;

var
  SellyAPI: TSellyAPI;

implementation

{ TSellyAPI }

constructor TSellyAPI.Create(const aEmail, aToken, aUseragent: string);
begin
  Email := aEmail;
  Token := aToken;
  UserAgent := aUseragent;
end;

function TSellyAPI.GetAllCoupons(const aPage: Integer): TSellyData;
begin
  Result := GetData('coupons', aPage);
end;

function TSellyAPI.GetAllOrders(const aPage: Integer): TSellyData;
begin
  Result := GetData('orders', aPage);
end;

function TSellyAPI.GetAllProductGroups(const aPage: Integer): TSellyData;
begin
  Result := GetData('product_groups', aPage);
end;

function TSellyAPI.GetAllProducts(const aPage: Integer): TSellyData;
begin
  Result := GetData('products', aPage);
end;

function TSellyAPI.GetAllQueries(const aPage: Integer): TSellyData;
begin
  Result := GetData('queries', aPage);
end;

function TSellyAPI.GetCoupon(const ID: string): TSellyData;
begin
  Result := GetData('coupons/' + ID);
end;

function TSellyAPI.GetData(const aURL_Path: string; const aPageIndex: Integer): TSellyData;
var
  http: TIdHTTP;
  ssl: TIdSSLIOHandlerSocketOpenSSL;
  compressor: TIdCompressorZLib;
begin
  http := TIdHTTP.Create(nil);
  try
    ssl := TIdSSLIOHandlerSocketOpenSSL.Create(nil);
    try
      compressor := TIdCompressorZLib.Create(nil);
      try
        ssl.SSLOptions.SSLVersions := [sslvTLSv1, sslvTLSv1_1, sslvTLSv1_2];
        http.Compressor := compressor;
        http.Request.UserAgent := UserAgent;
        http.Request.BasicAuthentication := True;
        http.Request.Username := Email;
        http.Request.Password := Token;
        http.IOHandler := ssl;
        http.HandleRedirects := True;

        Result.AsJson := http.Get(Format('https://selly.gg/api/v2/%s?page=%s', [aURL_Path, aPageIndex.ToString]));
        Result.Headers := TStringList.Create;
        Result.Headers.NameValueSeparator := ':';
        Result.Headers.Text := http.Response.RawHeaders.Text;
        Result.RateLimitRemaining := http.Response.RawHeaders.Values['X-RateLimit-Remaining'].ToInteger;
        if http.Response.RawHeaders.IndexOfName('X-Total-Pages') = -1 then
          Result.TotalPages := 1
        else
          Result.TotalPages := http.Response.RawHeaders.Values['X-Total-Pages'].ToInteger;
      finally
        compressor.Free;
      end;
    finally
      ssl.Free;
    end;
  finally
    http.Free;
  end;
end;

function TSellyAPI.GetProduct(const ID: string): TSellyData;
begin
  Result := GetData('products/' + ID);
end;

function TSellyAPI.GetProductGroup(const ID: string): TSellyData;
begin
  Result := GetData('product_groups/' + ID);
end;

function TSellyAPI.GetQuery(const ID: string): TSellyData;
begin
  Result := GetData('queries/' + ID);
end;

end.

