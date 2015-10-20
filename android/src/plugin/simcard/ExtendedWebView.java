package plugin.simcard;

import android.content.Context;
import android.content.ContentResolver;
import android.content.ContextWrapper;
import android.view.ContextThemeWrapper;
import android.app.Activity;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.webkit.WebSettings;
import android.widget.Toast;
import android.webkit.JavascriptInterface;
import android.view.Window;
import android.os.Bundle;
import android.util.Log;
import android.view.ViewGroup;
import android.widget.LinearLayout;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;
import android.net.wifi.WifiManager;
import android.telephony.SmsManager;
import android.net.Uri;
import android.database.Cursor;
import com.ansca.corona.CoronaEnvironment;
import com.ansca.corona.CoronaActivity;
import com.ansca.corona.CoronaLua;
import com.ansca.corona.CoronaRuntime;
import com.ansca.corona.CoronaRuntimeTask;

import com.naef.jnlua.LuaState;
import com.naef.jnlua.JavaFunction;
import com.naef.jnlua.NamedJavaFunction;

import java.lang.reflect.Method;
import java.lang.reflect.Field;
import java.lang.Object;
import java.lang.reflect.InvocationTargetException;

class NetworkState{

    private static NetworkState self = new NetworkState();
    private static Boolean[] state = {true, false};

    public static Boolean[] getLastState(){
        return state;
    }

    public static void setNetworkState(Boolean wifiState, Boolean mobileState){
        state[0] = wifiState;
        state[1] = mobileState;
    }

}

public class ExtendedWebView extends Activity {

    private WebView mWebView;

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        // The activity is being created.

        String extraUrl = "http://yogome.com";
        Bundle extras = getIntent().getExtras();
        if (extras != null){
            extraUrl = extras.getString("url");
        }

        Log.d("WEBVIEW", "I am in the ExtendedWebView");
        getWindow().requestFeature(Window.FEATURE_NO_TITLE);

        mWebView = new WebView(this);
        WebSettings viewSettings = mWebView.getSettings();
        viewSettings.setJavaScriptEnabled(true);

        mWebView.clearCache(true);

        mWebView.addJavascriptInterface(new WebAPI(), "apiYapp");
        mWebView.loadUrl(extraUrl);
        mWebView.setWebViewClient(new WebViewClient() {
            @Override
            public boolean shouldOverrideUrlLoading(WebView view, String url) {
                view.loadUrl(url);
                return true;
            }
        });
 
        this.setContentView(mWebView);
    }


    @Override
    protected void onStart() {
        super.onStart();
        // The activity is about to become visible.
    }
    @Override
    protected void onResume() {
        super.onResume();
        // The activity has become visible (it is now "resumed").
    }
    @Override
    protected void onPause() {
        super.onPause();
        // Another activity is taking focus (this activity is about to be "paused").
    }
    @Override
    protected void onStop() {
        super.onStop();
        // The activity is no longer visible (it is now "stopped")
        Log.d("WEBVIEW", "HiddenWebView");
        
    }
    @Override
    protected void onDestroy() {
        super.onDestroy();
        // The activity is about to be destroyed.
    }

    private class WebAPI{

        @JavascriptInterface
        public void completeSubscription(final int status){
            try{
                CoronaActivity activity = CoronaEnvironment.getCoronaActivity();
                activity.getRuntimeTaskDispatcher().send(new CoronaRuntimeTask(){
                    @Override
                    public void executeUsing(CoronaRuntime runtime){
                        LuaState L = runtime.getLuaState();
                        if(status > 0){
                            L.getGlobal("global_isSubscribed");
                            L.pushBoolean(true);
                            L.setGlobal("global_isSubscribed");
                        }
                    }
                });
                Log.d("WEBVIEW", "Got activity");
            }
            catch(Exception ex){
                Log.d("WEBVIEW", "Error getting activity");
            }
            finish();
        }
        
        @JavascriptInterface
        public void close(){
            finish();
        }

        @JavascriptInterface
        public String isNetworkCarrier(){
            Log.d("WEBVIEW", "Called isNetworkCarrier");

            CoronaActivity activity = CoronaEnvironment.getCoronaActivity();
            ConnectivityManager cm = (ConnectivityManager)activity.getSystemService(Context.CONNECTIVITY_SERVICE);
            NetworkInfo activeNetwork = cm.getActiveNetworkInfo();

            boolean isConnected = activeNetwork != null && activeNetwork.isConnectedOrConnecting();

            if (isConnected){
                Log.d("NETWORK", "I have a Connection");
                boolean isMobile = activeNetwork.getType() == ConnectivityManager.TYPE_MOBILE;

                if(isMobile){
                    return "true";
                }
            }

            return "false";
        }

        @JavascriptInterface
        public String enableNetworkCarrier() {
            Log.d("WEBVIEW", "Called enableNetworkCarrier");

            final CoronaActivity activity = CoronaEnvironment.getCoronaActivity();
            final ConnectivityManager cm = (ConnectivityManager)activity.getSystemService(Context.CONNECTIVITY_SERVICE);

            saveNetworkStatus(activity, cm);
            
            try{

                final Boolean enabled = true;

                WifiManager wifiManager = (WifiManager)activity.getSystemService(Context.WIFI_SERVICE);
                wifiManager.setWifiEnabled(false);

                final Class conmanClass = Class.forName(cm.getClass().getName());
                final Field connectivityManagerField = conmanClass.getDeclaredField("mService");
                connectivityManagerField.setAccessible(true);
                final Object connectivityManager = connectivityManagerField.get(cm);
                final Class connectivityManagerClass =  Class.forName(connectivityManager.getClass().getName());
                final Method setMobileDataEnabledMethod = connectivityManagerClass.getDeclaredMethod("setMobileDataEnabled", Boolean.TYPE);
                setMobileDataEnabledMethod.setAccessible(true);

                setMobileDataEnabledMethod.invoke(connectivityManager, enabled);

                return "true";
            }catch(Exception e){
                Log.d("NETWORK", "ERROR ENABLING NETWORK");
                return "false";
            }

        }

        private void saveNetworkStatus(CoronaActivity activity, ConnectivityManager cm){

            Boolean isMobile = false;
            Boolean isWifi = false;

            try {

                WifiManager wifiManager = (WifiManager)activity.getSystemService(Context.WIFI_SERVICE);
                isWifi = wifiManager.isWifiEnabled();

                Class cmClass = Class.forName(cm.getClass().getName());
                Method method = cmClass.getDeclaredMethod("getMobileDataEnabled");
                method.setAccessible(true); 
                isMobile = (Boolean)method.invoke(cm);

                NetworkState.setNetworkState(isWifi, isMobile);

                Log.d("NETWORK", Boolean.toString(isWifi));
                Log.d("NETWORK", Boolean.toString(isMobile));
                Log.d("NETWORK", "Saved last network state!");
            } catch (Exception e) {
                Log.d("NETWORK", "Error getting Mobile Data Status!");          
            }
        }    

        @JavascriptInterface
        public String restoreNetwork(){
            Log.d("WEBVIEW", "Called restoreNetwork");

            final CoronaActivity activity = CoronaEnvironment.getCoronaActivity();
            final ConnectivityManager cm = (ConnectivityManager)activity.getSystemService(Context.CONNECTIVITY_SERVICE);

            try{
                final Boolean isWifi = NetworkState.getLastState()[0];
                final Boolean isMobileData = NetworkState.getLastState()[1];

                WifiManager wifiManager = (WifiManager)activity.getSystemService(Context.WIFI_SERVICE);
                wifiManager.setWifiEnabled(isWifi);

                final Class conmanClass = Class.forName(cm.getClass().getName());
                final Field connectivityManagerField = conmanClass.getDeclaredField("mService");
                connectivityManagerField.setAccessible(true);
                final Object connectivityManager = connectivityManagerField.get(cm);
                final Class connectivityManagerClass =  Class.forName(connectivityManager.getClass().getName());
                final Method setMobileDataEnabledMethod = connectivityManagerClass.getDeclaredMethod("setMobileDataEnabled", Boolean.TYPE);
                setMobileDataEnabledMethod.setAccessible(true);

                setMobileDataEnabledMethod.invoke(connectivityManager, isMobileData);

                return "true";
            }catch(Exception e){
                Log.d("NETWORK", "ERROR ENABLIND NETWORK");
                return "false";
            }

        }

        @JavascriptInterface
        public String SendSMS(String shortcode, String message){
            Log.d("WEBVIEW", "Called sendSMS");

            try{
                SmsManager sms = SmsManager.getDefault();
                sms.sendTextMessage(shortcode, null, message, null, null);
                return "true";
            }catch(Exception e){
                return "false";
            }

            
        }

        @JavascriptInterface
        public String getLastMT(String shortcode){
            Log.d("WEBVIEW", "Called getLastMT");

            try{
                Uri inboxURI = Uri.parse("content://sms/inbox");

                String[] reqCols = new String[] {"_id", "address", "body"};

                ContentResolver cr = getContentResolver();

                Cursor c = cr.query(inboxURI, reqCols, "address = ?", new String[] {shortcode}, "date desc limit 1");

                if(c.moveToFirst()){
                    Log.v("QUERY", c.getString(c.getColumnIndex("body")));
                }

                return c.getString(c.getColumnIndex("body"));
            }catch(Exception e){
                return "";
            }
        }

        @JavascriptInterface
        public void checkSuscriptionStatus(){
            Log.d("WEBVIEW", "Called checkSuscriptionStatus");
        }
    }
}