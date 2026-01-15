global with sharing class ProfileSecurity {
    public Boolean isOk { get; set; }
    public ProfileSecurity(ObjectAccess objAcc){
        isOk = true;
    }

}