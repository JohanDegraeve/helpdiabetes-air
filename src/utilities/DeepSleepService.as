package utilities
{
	
	import com.hippoandfriends.helpdiabetes.airlibrary.AirNativeExtension;
	
	import flash.errors.IllegalOperationError;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	
	public class DeepSleepService extends EventDispatcher
	{
		private static var deepSleepTimer:Timer;
		
		private static var _instance:DeepSleepService = new DeepSleepService();
		
		/**
		 * how often to play the 1ms sound, in ms 
		 */
		private static var deepSleepInterval:int = 5000;
		private static var lastLogPlaySoundTimeStamp:Number = 0;
		
		public static function get instance():DeepSleepService
		{
			return _instance;
		}
		
		public function DeepSleepService()
		{
			//Don't allow class to be instantiated
			if (_instance != null) {
				throw new IllegalOperationError("DeepSleepService class is not meant to be instantiated!");
			}
		}
		
		public static function startDeepSleepService():void {
			clearDeepSleepTimer();
			startDeepSleepTimer();
		}
		
		public static function stopDeepSleepService():void {
			clearDeepSleepTimer();
		}
		
		private static function startDeepSleepTimer():void {
			myTrace("in startDeepSleepTimer");
			deepSleepTimer = new Timer(deepSleepInterval,0);
			deepSleepTimer.addEventListener(TimerEvent.TIMER, deepSleepTimerListener);
			deepSleepTimer.start();
		}
		
		private static function deepSleepTimerListener(event:Event):void {
			if (AirNativeExtension.isPlayingSound()) {
			} else {	
				if ((new Date()).valueOf() - lastLogPlaySoundTimeStamp > 1 * 1 * 1000) {
					myTrace("in deepSleepTimerListener, call playSound");
					lastLogPlaySoundTimeStamp = (new Date()).valueOf();
				}
				AirNativeExtension.playSound("../assets/1-millisecond-of-silence.mp3");
			}
		}
		
		private static function clearDeepSleepTimer():void {
			myTrace("in clearDeepSleepTimer");
			if (deepSleepTimer != null) {
				if (deepSleepTimer.running) {
					deepSleepTimer.stop();
				}
				deepSleepTimer = null;
			}
		}
		
		private static function myTrace(log:String):void 
		{
			Trace.myTrace("DeepSleepService.as " + log);
		}
	}
}