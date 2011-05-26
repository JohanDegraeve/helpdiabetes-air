package databaseclasses
{
	import flash.events.Event;
	
	public class UnitChangedEvent extends Event
	{
		public static const ITEM_SELECTED:String = "ItemSelected";
		
		public var index:int;
		
		public function UnitChangedEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
	}
}