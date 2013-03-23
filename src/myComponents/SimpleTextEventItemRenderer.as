/**
 Copyright (C) 2013  hippoandfriends
 
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/gpl.txt>.
 
 */
package myComponents
{
	/**
	 * itemrenderer for simpletextevent, which can be used in trackingview just to show a simple text message
	 */
	public class SimpleTextEventItemRenderer extends TrackingViewElementItemRenderer
	{
		public function SimpleTextEventItemRenderer()
		{
			super();
		}
		
		/**
		 * override the data property to initialize dayLineDisplay
		 */
		override public function set data(value:Object):void {
			super.data = value;
			label= (value as SimpleTextEvent).message;
		}
		
		override public function getHeight(item:TrackingViewElement = null):Number {
			return styleManager.getStyleDeclaration(".trackingItems").getStyle("trackingeventHeight");
		}
		
		override protected function drawBackground(unscaledWidth:Number, unscaledHeight:Number):void
		{
			//don't want to draw anything at all
		}
		
		override protected function createLabelDisplay():void
		{
			super.createLabelDisplay();
			labelDisplay.multiline = true;
			labelDisplay.wordWrap = true;
		}
		
		override protected function layoutContents(unscaledWidth:Number, unscaledHeight:Number):void {
			super.layoutContents(unscaledWidth,unscaledHeight);
			setElementPosition(labelDisplay,0 ,5);
			setElementSize(labelDisplay,unscaledWidth,getElementPreferredHeight(labelDisplay));
		}
	}
}