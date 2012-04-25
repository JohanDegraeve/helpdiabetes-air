/**
 Copyright (C) 2011  hippoandfriends
 
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
	import spark.components.IconItemRenderer;
	import spark.components.LabelItemRenderer;

	/**
	 * a superclass for the itemrenderers that are used for elements that can be in a trackingview<br>
	 * the goal is that the real itemrenderers extend from TrackingViewElementItemRenderer and override getHeight and getWidth and calculate the 
	 * height and width for the parameter item.<br>
	 */
	public class TrackingViewElementItemRenderer extends IconItemRenderer
	{
		
		public function TrackingViewElementItemRenderer() 
		{
		}
		
		/**
		 * the goal is that the real itemrenderers extend from TrackingViewElementItemRenderer and overrides getHeight calculate the 
		 * height and width for the parameter item.<br>
		 * if Item is null, then the implementation should try to calculate the height for the own data property<br>
		 */
		public function getHeight(item:TrackingViewElement = null):Number {
			return 0;				
		}
		
		override protected function drawBackground(unscaledWidth:Number, unscaledHeight:Number):void
		{
			if (down) {
				graphics.beginFill(0, 0.25);
				graphics.drawRect(0, 0, unscaledWidth, unscaledHeight);
				graphics.endFill();
			}
		}

		
		/**
		 * the goal is that the real itemrenderers extend from TrackingViewElementItemRenderer and override getHeight and getWidth and calculate the 
		 * height and width for the parameter item.<br>
		 
		public function getWidth(item:TrackingViewElement = null):Number {
			return 0;			
		}*/
	}
}