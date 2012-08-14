package utilities
{
	import com.google.analytics.GATracker;
	import com.google.analytics.debug.DebugConfiguration;
	import com.google.analytics.v4.Configuration;
	
	import databaseclasses.Settings;
	
	import flash.display.DisplayObject;
	
	public class MyGATracker extends GATracker
	{
		public function MyGATracker(display:DisplayObject, account:String, mode:String="AS3", visualDebug:Boolean=false, config:Configuration=null, debug:DebugConfiguration=null)
		{
			super(display, account, mode, visualDebug, config, debug);
		}
		
		override public function  trackPageview(pageURL:String=""):void {
			if ((new Date()).valueOf() - 1*7*24*60*60*1000 > new Number(Settings.getInstance().getSetting(Settings.SettingsFirstStartUp))) 
				super.trackPageview(pageURL);
		}
	}
}