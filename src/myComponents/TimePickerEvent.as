package myComponents
{
	import flash.events.Event;
	
	public class TimePickerEvent extends Event
	{
		public static const TIME_PICKER_SET: String = 'timePickerSet';
		public static const TIME_PICKER_CANCEL: String = 'timePickerCancel';
		
		public var time: Date;
		public function TimePickerEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
	}
}