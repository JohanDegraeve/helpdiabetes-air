package myComponents
{
	import mx.core.ClassFactory;

	/**
	 * implements IListElement so has a timestamp and an listElementRendererFunction<br>
	 * can be added in an arraylist of meals or tracking events, will actually simple show a date in a color which is weekday dependent to 
	 * clearly show the weekends
	 */
	public class DayLine implements IListElement
	{
		private var _timeStamp:Number;
		
		public function DayLine( timeStamp:Number)
		{
			this._timeStamp = timeStamp;
		}
		
		public function get timeStamp():Number {
			return _timeStamp
		}
		
		public function listElementRendererFunction ():ClassFactory {
			return new ClassFactory(DayLineItemRenderer);
		}

		public function set timeStamp(value:Number):void
		{
			_timeStamp = value;
		}

	}
}