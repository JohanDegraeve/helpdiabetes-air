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
/**
 * to draw a nice red line at 10h30,...etc.. whatever 
 */

package myComponents
{
	import mx.core.ClassFactory;
	
	public class TimeLine extends TrackingViewElement implements IListElement
	{
		public function TimeLine(timeStamp:Number)
		{
			super();
			this.timeStamp = timeStamp;
		}
		
		public function listElementRendererFunction():ClassFactory
		{
			return new ClassFactory(TimeLineItemRenderer);
		}
	}
}