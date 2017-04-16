package utilities
{
	import com.freshplanet.ane.AirBackgroundFetch.BackgroundFetch;

	public class Trace
	{
		public function Trace()
		{
		}
		
		public static function myTrace(log:String):void {
			BackgroundFetch.traceNSLog("helpdiabetestrace " + log);
		}

	}
}