package com.rodentcontrol.customer;

import android.content.Context;
import java.io.IOException;
import okhttp3.*;
import org.json.JSONObject;

public final class Api {
 private static final OkHttpClient client=new OkHttpClient.Builder().build();
 private static String url(String path){return BuildConfig.API_BASE_URL.replaceAll("/$","")+"/"+path.replaceAll("^/","");}
 private static JSONObject request(Context c,String method,String path,JSONObject body)throws Exception{
  RequestBody rb=body==null?null:RequestBody.create(body.toString(),MediaType.parse("application/json; charset=utf-8"));
  Request.Builder b=new Request.Builder().url(url(path));
  if(rb!=null)b.method(method,rb);else b.method(method,null);
  String token=c==null?"":SecureStore.token(c);if(!token.isEmpty())b.header("Authorization","Bearer "+token);
  try(Response r=client.newCall(b.build()).execute()){
   String text=r.body()!=null?r.body().string():"{}";JSONObject j=new JSONObject(text);
   if(!r.isSuccessful()||!j.optBoolean("ok",false))throw new ApiException(j.optString("error","Yêu cầu thất bại"),r.code());
   return j;
  }
 }
 public static JSONObject login(String u,String p,String device)throws Exception{JSONObject b=new JSONObject();b.put("username",u);b.put("password",p);b.put("device_name",device);return request(null,"POST","customer_login.php",b);}
 public static JSONObject verify(Context c,String challenge,String otp,String device)throws Exception{JSONObject b=new JSONObject();b.put("challenge",challenge);b.put("otp",otp);b.put("device_name",device);return request(c,"POST","customer_verify_otp.php",b);}
 public static JSONObject forgotPassword(String u)throws Exception{JSONObject b=new JSONObject();b.put("username",u);return request(null,"POST","customer_forgot_password.php",b);}
 public static JSONObject resetPassword(String token,String pass)throws Exception{JSONObject b=new JSONObject();b.put("token",token);b.put("new_password",pass);return request(null,"POST","customer_reset_password.php",b);}
 public static byte[] floorPlan(Context c,int siteId,int planId)throws Exception{Request.Builder b=new Request.Builder().url(url("customer_floor_plan.php?site_id="+siteId+"&floor_plan_id="+planId)).get();String token=SecureStore.token(c);if(token.isEmpty())throw new ApiException("Chưa đăng nhập",401);b.header("Authorization","Bearer "+token);try(Response r=client.newCall(b.build()).execute()){if(!r.isSuccessful()||r.body()==null)throw new ApiException("Không tải được sơ đồ",r.code());return r.body().bytes();}}
 public static JSONObject dashboard(Context c)throws Exception{return request(c,"GET","customer_dashboard.php",null);}
 public static JSONObject sites(Context c)throws Exception{return request(c,"GET","customer_sites.php",null);}
 public static JSONObject site(Context c,int id)throws Exception{return request(c,"GET","customer_site.php?site_id="+id,null);}
 public static JSONObject reports(Context c)throws Exception{return request(c,"GET","customer_reports.php",null);}
 public static JSONObject incidents(Context c)throws Exception{return request(c,"GET","customer_incidents.php",null);}
 public static void logout(Context c)throws Exception{request(c,"POST","customer_logout.php",new JSONObject());SecureStore.clear(c);}
 public static final class ApiException extends IOException{public final int code;ApiException(String m,int c){super(m);code=c;}}
}
