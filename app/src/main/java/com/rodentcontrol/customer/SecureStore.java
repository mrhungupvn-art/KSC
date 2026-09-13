package com.rodentcontrol.customer;

import android.content.Context;
import android.content.SharedPreferences;
import androidx.security.crypto.EncryptedSharedPreferences;
import androidx.security.crypto.MasterKey;

public final class SecureStore {
    private static final String FILE="customer_secure";
    private static SharedPreferences prefs(Context c){
        try{
            MasterKey key=new MasterKey.Builder(c).setKeyScheme(MasterKey.KeyScheme.AES256_GCM).build();
            return EncryptedSharedPreferences.create(c,FILE,key,EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM);
        }catch(Exception e){throw new IllegalStateException("Không khởi tạo được kho bảo mật",e);}
    }
    public static void putToken(Context c,String token){prefs(c).edit().putString("token",token).apply();}
    public static String token(Context c){return prefs(c).getString("token","");}
    public static void clear(Context c){prefs(c).edit().clear().apply();}
}
