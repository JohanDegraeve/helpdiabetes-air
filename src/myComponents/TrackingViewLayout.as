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
	import flash.events.Event;
	import flash.geom.Rectangle;
	
	import mx.collections.IList;
	import mx.core.ClassFactory;
	import mx.core.ILayoutElement;
	import mx.rpc.events.HeaderEvent;
	
	import spark.components.DataGroup;
	import spark.components.supportClasses.GroupBase;
	import spark.layouts.BasicLayout;
	import spark.layouts.VerticalLayout;
	
	public class TrackingViewLayout extends BasicLayout {
		
		//private var _lastIndexInView:int;
		private var _firstIndexInView:int;
		private var yToIndex:Vector.<int>; 
		private var indexToY:Vector.<int>; 
		private var currentFirstIndex:int;
		private var currentLastIndex:int;
		private var _containerWidth:Number;
		private var _containerHeight:Number;
		
 //  		private var addExtraItems:int;
		
		/**
		 * 
		 */ 
		override public function measure():void {
			if (!useVirtualLayout) {
				super.measure();
				return;
			}
			
			var layoutTarget:GroupBase = target;
			if (!layoutTarget)
				return;
			var dataGroupTarget:DataGroup = layoutTarget as DataGroup;
			if (dataGroupTarget.width == 0 || dataGroupTarget.height == 0) {
				_containerWidth = _containerHeight = -1;
				return;
			}

			
			var totalHeight:Number = 0;
			var dataProvider:IList = dataGroupTarget.dataProvider;
			if (!dataProvider || !dataProvider.length)
				return;
			var count:int = dataProvider.length;
			
			var elementHeight:Number;
			yToIndex = new Vector.<int>();
			indexToY = new Vector.<int>();
			var d:Object ;
			//loop though all the elements elements
			for (var i:int = 0; i < count; i++) {
				d = dataProvider.getItemAt(i);
				elementHeight = ((d as IListElement).listElementRendererFunction().newInstance() as TrackingViewElementItemRenderer).getHeight((d as TrackingViewElement));
				//add the index to vector
				addToVectorY(i, totalHeight /* + 1*/, elementHeight);//I'm not adding the 1 here because I'm also not doing that in the getHeight method in the itemrenderer, meaning the elements overlap with one pixel height
				totalHeight += elementHeight ;
				addToVectorIndex(i, totalHeight - elementHeight );
			}
			//just adding one element because I use this last value to calculate the size of the really last element (ie the max-1 array element) in method updatevirtual
			addToVectorIndex(i,totalHeight);
			
			layoutTarget.measuredWidth = dataGroupTarget.width;
			layoutTarget.measuredHeight = totalHeight;
			layoutTarget.measuredMinWidth = dataGroupTarget.width;
			layoutTarget.measuredMinHeight = totalHeight; 
			//setContentSize(totalWidth, totalHeight);, i don't think this should be done in  measure
		}
		
		private function addToVectorY(index:int, startHeight:Number, elementHeight:Number):void {
			var end:int = startHeight + elementHeight ;
			for (var i:int = startHeight; i < end; i++) {
				yToIndex[i] = index;
			}
		}
		
		private function addToVectorIndex(index:int, y:int):void {
			indexToY[index] = y;
		}
		
		override protected function scrollPositionChanged():void {
			if (!useVirtualLayout) {
				super.scrollPositionChanged();
				return;
			}
			
			var g:GroupBase = target;
			if (!g)
				return;     
			updateScrollRect(g.width, g.height);
			
			var n:int = g.numElements - 1;
			if (n < 0) {
				setIndexInView(-1, -1);
				return;
			}
			
			var scrollR:Rectangle = getScrollRect();
			if (!scrollR) {
				setIndexInView(0, n);
				return;    
			}
			
			var y0:Number = scrollR.top;
			var y1:Number = scrollR.bottom - .0001;
			if (y1 <= y0) {
				setIndexInView(0, n);
				return;
			}
			
			var i0:int, i1:int;
			if (y0 < 0) {
				i0 = 0;
				i1 = yToIndex.length - 1 > g.height ? yToIndex[g.height + 1]  : g.numElements - 1;
				setIndexInView(i0, i1);
				return;	
			}
			
			if (y1 < yToIndex.length - 1) {
				i0 = yToIndex[Math.floor(y0)];
				i1 = yToIndex[Math.ceil(y1)];
			} else {
				if (yToIndex.length - 1 - g.height < 0)
					i0 = 0;
				else
					i0 = yToIndex[yToIndex.length - 1 - g.height];
				i1 = yToIndex[yToIndex.length - 1];
			}
			//			trace("y0, y1: " + y0 + " | " + y1);
			//			trace("i0, i1: " + i0 + " | " + i1);
			//			trace("currentFirstIndex, currentLastIndex : " + currentFirstIndex + " | " + currentLastIndex);
			setIndexInView(i0, i1);
			//invalidate display list only if we have items that are not already renderered
			if (i0 < currentFirstIndex || i1 > currentLastIndex) {
				g.invalidateDisplayList();
			}
		}
		
		override public function updateDisplayList(containerWidth:Number, containerHeight:Number):void {
			if (useVirtualLayout)
				updateVirtual(containerWidth, containerHeight);
			else
				updateNonVirtual(containerWidth, containerHeight);
			
		}
		
		/**
		 * Lay down all the items - this is used when useVirtualLayout is set to false
		 */ 
		private function updateNonVirtual(containerWidth:Number, containerHeight:Number):void {
			var layoutTarget:GroupBase = target;
			if (!(layoutTarget as DataGroup).dataProvider || (layoutTarget as DataGroup).dataProvider.length == 0)
				return;
			
			if (!_containerWidth)
				_containerWidth = containerWidth;
			if (!_containerHeight)
				_containerHeight = containerHeight;
			
			var y:Number = 0;
			var elementHeight:Number, prevElementHeight:Number;
			
			y = 0;
			var count:int = layoutTarget.numElements;
			var element:ILayoutElement;
			
			for (var i:int = 0; i < count; i++) {
				// get the current element, we're going to work with the
				// ILayoutElement interface
				element = layoutTarget.getElementAt(i);
				elementHeight = ((element as IListElement).listElementRendererFunction().newInstance() as TrackingViewElementItemRenderer).getHeight((element as TrackingViewElement));
				// Resize the element to its preferred size by passing
				// NaN for the width and height constraints
				element.setLayoutBoundsSize(NaN, NaN);
				element.setLayoutBoundsSize(layoutTarget.width, elementHeight);
				
				// Position the element
				element.setLayoutBoundsPosition(0, y);
				prevElementHeight = elementHeight;
				
			}
			// Scrolling support - update the content size
			layoutTarget.setContentSize(containerWidth, y);
		}
		
		/**
		 * Lay down the current items in the view - this is used when useVirtualLayout is set to true
		 */
		private function updateVirtual(containerWidth:Number, containerHeight:Number):void {
			var layoutTarget:GroupBase = target;
			if (!(layoutTarget as DataGroup).dataProvider || (layoutTarget as DataGroup).dataProvider.length == 0)
				return;
			
			if (!_containerWidth)
				_containerWidth = containerWidth;
			if (!_containerHeight)
				_containerHeight = containerHeight;
			//a resize of the component occured
			if (_containerWidth != containerWidth || _containerHeight != containerHeight) {
				_containerWidth = containerWidth;
				_containerHeight = containerHeight;
				//addExtraItems = 0;
				measure();
				//set the new _firstIndex and _lastIndex
				scrollPositionChanged();
			}
			var y:Number = 0;
			//var maxWidth:Number = 0;
			//var maxHeight:Number = 0;
			var elementHeight:Number;
			
			//provide the initial values
			if (!_firstIndexInView) 
				_firstIndexInView = 0;
			currentFirstIndex = _firstIndexInView;
			if (currentFirstIndex < 0 )
				currentFirstIndex = 0;
			
			//y = indexToY[currentFirstIndex];
			var count:int = currentFirstIndex;
			var element:ILayoutElement;
			
			do  {
				element = layoutTarget.getVirtualElementAt(count);
				
				elementHeight = indexToY[count + 1] - indexToY[count];//there's always a count + 1 element because I've added an extra el
				
				element.setLayoutBoundsSize(layoutTarget.width, elementHeight);
				
				
				// Position the element
				element.setLayoutBoundsPosition(0, y);

				y = y + elementHeight;

				currentLastIndex = count;//seems used in scrollpositionchanged
				count++;
			} while ((y < containerHeight && (count < (layoutTarget as DataGroup).dataProvider.length)));
		}
		
		private function setIndexInView(firstIndex:int, lastIndex:int):void {
			if ((_firstIndexInView == firstIndex) /*&& (_lastIndexInView == lastIndex)*/)
				return;
			//			trace("setIndexInView(" + firstIndex + ", " + lastIndex + ")");
			_firstIndexInView = firstIndex;
			//_lastIndexInView = lastIndex;
			dispatchEvent(new Event("indexInViewChanged"));
		}
	}
}