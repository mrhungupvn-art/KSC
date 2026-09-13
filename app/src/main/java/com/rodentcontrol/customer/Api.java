package com.rodentcontrol.customer;
import android.content.Context;
import java.io.IOException;
import okhttp3.*;
import org.json.JSONObject;
import java.util.concurrent.TimeUnit;

public final class Api {
 private static final OkHttpClient client=new OkHttpClient.Builder().connectTimeout(15,TimeUnit.SECONDS).readTimeout(30,TimeUnit.SECONDS).build();
 private static String url(String path){return BuildConfig.API_BASE_URL.replaceAll("/$","")+"/"+path.replaceAll("^/","");}
 private static JSONObject request(Context c,String method,String path,JSONObject body)throws Exception{
  RequestBody rb=body==null?null:RequestBody.create(body.toString(),MediaType.parse("application/json; charset=utf-8"));
  Request.Builder b=new Request.Builder().url(url(path)).header("Accept","application/json");
  if(rb!=null)b.method(method,rb);else b.method(method,null);
  if(c!=null){String token=SecureStore.token(c);if(!token.isEmpty())b.header("Authorization","Bearer "+token);}
  try(Response r=client.newCall(b.build()).execute()){
   String text=r.body()!=null?r.body().string():"{}";JSONObject j=new JSONObject(text);
   if(!r.isSuccessful()||!j.optBoolean("ok",false))throw new ApiException(j.optString("error","Yêu cầu thất bại"),r.code());
   return j;
  }
 }
 public static JSONObject login(String u,String p,String device)throws Exception{
  JSONObject b=new JSONObject().put("username",u).put("password",p).put("device_label",device);
  return request(null,"POST","login.php",b);
 }
 public static JSONObject forgotPassword(String email)throws Exception{return request(null,"POST","forgot-password.php",new JSONObject().put("email",email));}
 public static JSONObject resetPassword(String email,String code,String password)throws Exception{return request(null,"POST","reset-password.php",new JSONObject().put("email",email).put("code",code).put("password",password));}
 public static JSONObject dashboard(Context c)throws Exception{return request(c,"GET","dashboard.php",null);}
 public static JSONObject sites(Context c)throws Exception{return request(c,"GET","sites.php",null);}
 public static JSONObject site(Context c,int id)throws Exception{return request(c,"GET","site.php?site_id="+id,null);}
 public static JSONObject reports(Context c)throws Exception{return request(c,"GET","reports.php",null);}
 public static JSONObject incidents(Context c)throws Exception{return request(c,"GET","incidents.php",null);}
 public static byte[] floorPlan(Context c,int siteId,int planId)throws Exception{
  String token=SecureStore.token(c);if(token.isEmpty())throw new ApiException("Chưa đăng nhập",401);
  Request.Builder b=new Request.Builder().url(url("floor_plan.php?site_id="+siteId+"&floor_plan_id="+planId)).get().header("Authorization","Bearer "+token);
  try(Response r=client.newCall(b.build()).execute()){if(!r.isSuccessful()||r.body()==null)throw new ApiException("Không tải được sơ đồ",r.code());return r.body().bytes();}
 }
 public static void logout(Context c)throws Exception{try{request(c,"POST","logout.php",new JSONObject());}finally{SecureStore.clear(c);}}
 public static final class ApiException extends IOException{public final int code;ApiException(String m,int c){super(m);code=c;}}
}
