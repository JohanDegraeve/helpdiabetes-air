package com.hippoandfriends.helpdiabetes.airlibrary
{
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.external.ExtensionContext;
	
	public class AirNativeExtension extends EventDispatcher
	{
		private static var context : ExtensionContext; 
		private static const EXTENSION_ID : String = "com.hippoandfriends.helpdiabetes.AirNativeExtension";
		public function AirNativeExtension(target:IEventDispatcher=null)
		{
			super(target);
		}
		
		public static function traceNSLog(log:String) : void { 
			if (context != null) {
				context.call( "traceNSLog", log ); 
			}
		}
		
		public static function init():void {
			if (context == null) {
				context = ExtensionContext.createExtensionContext("com.hippoandfriends.helpdiabetes.AirNativeExtension","");
				context.call("init");
			}
		}
		
		public static function isPlayingSound():Boolean {
			return (context.call("isPlayingSound") as Boolean);
		}

		public static function playSound(sound:String):void {
			context.call("playSound", sound);
		}
		

	}
}