package com.rodentcontrol.customer;
import android.content.Intent;import android.os.Bundle;import android.widget.*;import androidx.appcompat.app.AppCompatActivity;import java.util.concurrent.Executors;
public class LoginActivity extends AppCompatActivity{
 EditText user,pass; TextView msg;
 protected void onCreate(Bundle b){super.onCreate(b);setContentView(R.layout.activity_login);user=findViewById(R.id.username);pass=findViewById(R.id.password);msg=findViewById(R.id.message);findViewById(R.id.login).setOnClickListener(v->login());findViewById(R.id.forgot).setOnClickListener(v->startActivity(new Intent(this,ForgotPasswordActivity.class)));}
 void login(){String u=user.getText().toString().trim(),p=pass.getText().toString();if(u.isEmpty()||p.isEmpty()){msg.setText("Vui lòng nhập tài khoản và mật khẩu.");return;}msg.setText("Đang xác thực...");Executors.newSingleThreadExecutor().execute(()->{try{org.json.JSONObject r=Api.login(u,p,"Customer Android");runOnUiThread(()->{Intent i=new Intent(this,OtpActivity.class);i.putExtra("challenge",r.optString("challenge"));startActivity(i);});}catch(Exception e){runOnUiThread(()->msg.setText(e.getMessage()));}});}
}
