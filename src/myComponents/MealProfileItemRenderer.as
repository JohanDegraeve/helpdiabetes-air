package myComponents
{
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import mx.graphics.BitmapFillMode;
	
	import spark.components.Image;
	import spark.components.LabelItemRenderer;
	
	public class MealProfileItemRenderer extends LabelItemRenderer
	{
		private var graphImage:Image;
		[Embed(source="assets/ic_tab_tracking_selected.png")]
		[Bindable]
		public var graphIcon:Class;

		static private var ITEM_HEIGHT:int = 48;
		static private var ICON_WIDTH:int = 48;
		static private var offsetToPutTextInTheMiddle:int;
		
		/**
		 * to dispatch event data graph button as clicked
		 */public static var GRAPH_CLICKED:String = "MEALPROFILEITEMRENDER_GRAPH_CLICKED";
		
		public function MealProfileItemRenderer()
		{
			super();
			if (offsetToPutTextInTheMiddle == 0)
				offsetToPutTextInTheMiddle = styleManager.getStyleDeclaration(".trackingItems").getStyle("offsetToPutTextInTheMiddle");
		}
		
		/**
		 * @private
		 *
		 * Override this setter to respond to data changes
		 */
		override public function set data(value:Object):void
		{
			super.data = value;
			label = value as String;
		} 
		
		/**
		 * @private
		 * 
		 * Override this method to change how the item renderer 
		 * sizes itself. For performance reasons, do not call 
		 * super.measure() unless you need to.
		 */ 
		override protected function measure():void
		{
			super.measure();
			// measure all the subcomponents here and set measuredWidth, measuredHeight, 
			// measuredMinWidth, and measuredMinHeight      		
		}
		
		/**
		 * @private
		 * 
		 * Override this method to change how the background is drawn for 
		 * item renderer.  For performance reasons, do not call 
		 * super.drawBackground() if you do not need to.
		 */
		override protected function drawBackground(unscaledWidth:Number, 
												   unscaledHeight:Number):void
		{
			//only draw a border line
			graphics.lineStyle(1, 0, 0.75);
			graphics.moveTo(0,unscaledHeight - 1);
			graphics.lineTo(unscaledWidth,unscaledHeight - 1);
			graphics.endFill();
		}
		
		/**
		 * @private
		 *  
		 * Override this method to change how the background is drawn for this 
		 * item renderer. For performance reasons, do not call 
		 * super.layoutContents() if you do not need to.
		 */
		override protected function layoutContents(unscaledWidth:Number, 
												   unscaledHeight:Number):void
		{
			if (graphImage) {
				setElementSize(graphImage,ICON_WIDTH,ITEM_HEIGHT);
				setElementPosition(graphImage,unscaledWidth - ICON_WIDTH,0);
			}
			setElementSize(labelDisplay,unscaledWidth - ICON_WIDTH, ITEM_HEIGHT);
			setElementPosition(labelDisplay,0,offsetToPutTextInTheMiddle);
		}
		
		override protected function createChildren():void {
			super.createChildren();
			if (!graphImage) {
				graphImage = new Image();
				graphImage.fillMode = BitmapFillMode.CLIP;
				graphImage.source = graphIcon;
				graphImage.addEventListener(MouseEvent.CLICK,graphClicked);
				addChild(graphImage);
			}
		}
		
		private function graphClicked(event:Event):void {
			this.dispatchEvent(new Event(GRAPH_CLICKED,true,true));
		}
	}
}