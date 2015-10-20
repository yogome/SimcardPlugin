//  SimCard.java
//
//  2015 Jonatan Santos
//
package plugin.simcard;


import android.util.Log;
import android.telephony.TelephonyManager;
import android.content.Context;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import com.naef.jnlua.LuaState;
import com.naef.jnlua.JavaFunction;
import com.naef.jnlua.NamedJavaFunction;
import com.ansca.corona.CoronaActivity;
import com.ansca.corona.CoronaEnvironment;
import java.util.Hashtable;

public class SimCard{

	public Hashtable<String, String> getData(){

		Hashtable<String, String> simData = new Hashtable<String, String>();

		try{		
		CoronaActivity activity = CoronaEnvironment.getCoronaActivity();
		final TelephonyManager tm = (TelephonyManager)activity.getSystemService(Context.TELEPHONY_SERVICE);

        simData.put("DeviceId", tm.getDeviceId());
        simData.put("DeviceSoftwareVersion", tm.getDeviceSoftwareVersion());
        simData.put("NetworkOperator", tm.getNetworkOperator());
        //simData.put("NetworkOperator", "71606");
        simData.put("NetworkOperatorName", tm.getNetworkOperatorName());
        simData.put("SimOperator", tm.getSimOperator());
        simData.put("SimSerialNumber", tm.getSimSerialNumber());
        simData.put("SimState", Integer.toString(tm.getSimState()));
        //simData.put("isSMSCapable", Boolean.toString(tm.isSmsCapable()));

        return simData;	
		}catch(Exception e){
			return simData;
		}
		
	}

	public Integer isNetworkCarrier(){
		return 0;
	}

}
