package utilities
{
	import com.hippoandfriends.helpdiabetes.airlibrary.AirNativeExtension;

	public class Trace
	{
		public function Trace()
		{
		}
		
		public static function myTrace(log:String):void {
			AirNativeExtension.traceNSLog("helpdiabetestrace " + log);
		}

	}
}