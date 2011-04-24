package databaseclasses
{
	import flash.events.Event;
	
	[Event(name="ResultEvent",type="events.DatabaseEvent")]
	[Event(name="ErrorEvent",type="events.DatabaseEvent")]
	
	public class DatabaseEvent extends Event
	{
		
		public static const RESULT_EVENT:String = "ResultEvent";
		public static const ERROR_EVENT:String = "ErrorEvent";
		
		
		public var data:*;
		public var lastInsertRowID:Number;
		
		public function DatabaseEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
	}
}