package com.rodentcontrol.customer;
import android.content.Intent;import android.os.Bundle;import android.widget.*;import androidx.appcompat.app.AppCompatActivity;import java.util.concurrent.Executors;
public class OtpActivity extends AppCompatActivity{
 EditText otp;TextView msg;String challenge;
 protected void onCreate(Bundle b){super.onCreate(b);setContentView(R.layout.activity_otp);challenge=getIntent().getStringExtra("challenge");otp=findViewById(R.id.otp);msg=findViewById(R.id.message);findViewById(R.id.verify).setOnClickListener(v->verify());}
 void verify(){String code=otp.getText().toString().trim();if(!code.matches("[0-9]{6}")){msg.setText("Nhập mã OTP 6 số.");return;}Executors.newSingleThreadExecutor().execute(()->{try{org.json.JSONObject r=Api.verify(this,challenge,code,"Customer Android");SecureStore.putToken(this,r.getString("token"));runOnUiThread(()->{startActivity(new Intent(this,MainActivity.class));finishAffinity();});}catch(Exception e){runOnUiThread(()->msg.setText(e.getMessage()));}});}
}
