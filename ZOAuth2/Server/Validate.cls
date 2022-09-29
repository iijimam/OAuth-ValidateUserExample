Class ZOAuth2.Server.Validate Extends %OAuth2.Server.Validate
{

/// Your custom ValidateUser method must return true (1) only if the username and password refer to a valid user
/// based on whatever criteria you choose to implement.  It must return false in other cases. <p>
/// If password="", then the user is already logged into an existing session and the password
/// does not need to be validated.<p>
/// In addition, this method receives the properties array and can further modify it;
/// this correspond to the Properties property of %OAuth2.Server.Token. 
/// The authorization server will always add the "iss" (URL of authorization server),
/// "sub" (client_id), and "exp" (expiration time in seconds since December 31st, 1840)
/// to ClaimValues and "client_id" (client_id of the requesting client) to CusotmProperties 
/// after return from ValidateUser if they have not already been added.<p>
/// This sample ValidateUser method validates the user based on the users for this instance.
ClassMethod ValidateUser(username As %String, password As %String, scope As %ArrayOfDataTypes, properties As %OAuth2.Server.Properties, Output sc As %Status) As %Boolean
{

    //オリジナルテーブルのチェックを追加
    /*
        カスタマイズのValidateUserメソッドを動かすため、以下の設定を変更します。
        OAuthサーバの設定の「カスタマイズ」タブの「ユーザクラスを検証」に
        カスタマイズクラス名を指定します（例：ZOAuth2.Server.Validate）
        メモ：元は、スーパークラスの%OAuth2.Server.Validateが設定されていて、IRIS内ユーザによる検証を行っています
    */

    /*注意：トークン取得時にユーザチェック用テーブルに対してSELECT権限がないと以下SELECTを実行できません。
     テスト時、以下設定例を試しています
    ＜設定例＞
    1) ロールを作成し、そのロールに　ZMyAuth.UserTbl　のSELECT権限を設定
    2) OAuthサーバの設定の「カスタマイズ」タブのロールに　1)のロールを追加
    */
    set stmt=##class(%SQL.Statement).%New()
    set st=stmt.%Prepare("select Roles from ZMyAuth.UserTbl WHERE UserID=? And Password=?")
    #dim rset As %SQL.StatementResult
    set rset=stmt.%Execute(username,password)
    while rset.%Next() {
        set roles=rset.Roles
    }

    //例では、ロールが取得できない＝ユーザが存在しないとしてとりあえずエラーを返しています
    if $get(roles)="" {
        set status=$$$ERROR($$$UserDoesNotExist,username)
    }
    if $$$ISERR(sc) {
        //set ^iijima("error")=$system.Status.GetErrorText(sc)
        quit 0
    }

    //ユーザに対するIRIS内ロール付与
    Do properties.CustomProperties.SetAt(roles,"roles")

    //以下オリジナルを真似
    // Setup claims for profile and email OpenID Connect scopes.
	Do properties.SetClaimValue("sub",username)
	Do properties.SetClaimValue("preferred_username",username)

    /*
    //以下、IRIS内ユーザの場合に取れる情報なのでコメント↓
    //  Set sc=##class(Security.Users).GetProperties(user,.prop)
	If $get(prop("EmailAddress"))'="" {
		Do properties.SetClaimValue("email",prop("EmailAddress"))
		Do properties.SetClaimValue("email_verified",0,"boolean")
	}
    	If $get(prop("FullName"))'="" {
		Do properties.SetClaimValue("name",prop("FullName"))
	}
	If $get(prop("PhoneNumber"))'="" {
		Do properties.SetClaimValue("phone_number",prop("PhoneNumber"))
		Do properties.SetClaimValue("phone_number_verified",0,"boolean")
	}
	
	// Setup claim for when user last updated.
	If $get(prop("LastModifiedDateTime"))'="" {
		Set time=##class(%OAuth2.Utils).TimeInSeconds(prop("LastModifiedDateTime"),0)
		Do properties.SetClaimValue("updated_at",time,"number")
	}
    */
	Quit 1
}

ClassMethod CreateOriginalUserTable()
{
    &sql(create table ZMyAuth.UserTbl(UserID VARCHAR(10),Password VARCHAR(50),Roles VARCHAR(50)))
    &sql(insert into ZMyAuth.UserTbl (UserID,Password,Roles) VALUES('User1','User1','%All'))
    &sql(insert into ZMyAuth.UserTbl (UserID,Password,Roles) VALUES('User2','User2','%All'))
}

}
