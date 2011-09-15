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
	
	import spark.components.DataGroup;
	import spark.components.supportClasses.GroupBase;
	import spark.layouts.BasicLayout;
	import spark.layouts.VerticalLayout;
	
	public class TrackingViewLayout extends BasicLayout {
		
		private var _lastIndexInView:int;
		private var _firstIndexInView:int;
		private var yToIndex:Vector.<int>; 
		private var indexToY:Vector.<int>; 
		private var _currentFirstIndexInView:int;
		private var _currentLastIndexInView:int;
		
		
		/**
		 * 
		 */ 
		override public function measure():void {
			trace("measure");
			var layoutTarget:GroupBase = target;
			if (!layoutTarget)
				return;
			var dataGroupTarget:DataGroup = layoutTarget as DataGroup;
			/*if (dataGroupTarget.width == 0 || dataGroupTarget.height == 0) {
				_containerWidth = _containerHeight = -1;
				return;
			}*/

			
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
				elementHeight = ((d as IListElement).listElementRendererFunction().newInstance() as TrackingViewElementItemRenderer).getHeight((d as TrackingViewElement)) ;
				//add the index to vector
				addToVectorY(i, totalHeight /* + 1*/, elementHeight);//I'm not adding the 1 here because I'm also not doing that in the getHeight method in the itemrenderer, meaning the elements overlap with one pixel height
				totalHeight += elementHeight ;
				addToVectorIndex(i, totalHeight - elementHeight );
			}
			//just adding one element because I use this last value to calculate the size of the really last element (ie the max-1 array element) in method updatevirtual
			addToVectorIndex(i,totalHeight);
			
			layoutTarget.measuredWidth = dataGroupTarget.width;
			layoutTarget.measuredHeight = totalHeight ;
			layoutTarget.measuredMinWidth = dataGroupTarget.width;
			layoutTarget.measuredMinHeight = totalHeight; 
			layoutTarget.setContentSize(dataGroupTarget.width, totalHeight);// i don't think this should be done in  measure
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
			trace("scrollpositionchanged " + y0 + " , " + y1);
			if (y1 <= y0) {
				setIndexInView(0, n);
				return;
			}

			var i0:int;
			var i1:int;
			if (y0 < 0) {
				i0 = 0;
				i1 = yToIndex.length - 1 > g.height ? yToIndex[g.height + 1]  : g.numElements - 1;
				setIndexInView(i0,i1);
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
			trace ("i0,i1 = " + i0 + " , " + i1);
			setIndexInView(i0,i1);
			//invalidate display list only if we have items that are not already renderered
			//trace("i0, i1: " + i0 + " | " + i1);
			//trace("_currentFirstIndexInView, _currentLastIndexInView : " + _currentFirstIndexInView + " | " + _currentLastIndexInView);
			if (i0 < _currentFirstIndexInView || i1 > _currentLastIndexInView) {
				g.invalidateDisplayList();
				
				trace("invalidatedisplaylist called with i0,i1 = " + i0 + "," + i1 + " and _currentFirstIndexInView, _currentLastIndexInView = " + _currentFirstIndexInView + "," + _currentLastIndexInView);
				trace ("_firstIndexInView, _lastIndexInView = " + _firstIndexInView + "," + _lastIndexInView  );
			}
		}
		
		override public function updateDisplayList(containerWidth:Number, containerHeight:Number):void {
			trace ("now in updatedisplaylist");
			var layoutTarget:GroupBase = target;
			if (!(layoutTarget as DataGroup).dataProvider || (layoutTarget as DataGroup).dataProvider.length == 0)
				return;
	
			/*	_currentFirstIndexInView = 9;
			_currentLastIndexInView = 20;
			_firstIndexInView = 11;
			_lastIndexInView = 21;*/
			
			var y:Number = 0;
			var elementHeight:Number;
			
			//provide the initial values
			if (!_firstIndexInView) 
				_firstIndexInView = 0;
			
			if (!_lastIndexInView) //if lastindexinview isn't set yet then set it to zero
				_lastIndexInView = 0;
			if (_lastIndexInView == 0) //this will force to set lastindexinview correctly (and also first)
				scrollPositionChanged();
			
			/*_lastIndexInView +=20;
			if (_lastIndexInView > layoutTarget.numElements - 1)
				_lastIndexInView = layoutTarget.numElements - 1;*/
			
			
			_currentFirstIndexInView = (_firstIndexInView < 0 ? 0 : _firstIndexInView) ;
			
			y = indexToY[_currentFirstIndexInView ];
			var count:int = _currentFirstIndexInView;
			var startPosition:int = y;
			var element:ILayoutElement;
			
			do  {
				element = layoutTarget.getVirtualElementAt(count);
				
				elementHeight = indexToY[count + 1] - indexToY[count];//there's always a count + 1 element because I've added an extra el
				//element.setLayoutBoundsSize(NaN, NaN);
				element.setLayoutBoundsSize(layoutTarget.width, elementHeight);
				element.setLayoutBoundsPosition(0, y);

				y = y + elementHeight;
				
				count++;
				//var temp:Object = y - startPosition;
				//var temp2:Object = (layoutTarget as DataGroup).dataProvider.length;
			} while (count <= _lastIndexInView)//( ((y - startPosition) < containerHeight) && (count < (layoutTarget as DataGroup).dataProvider.length) );
			_currentLastIndexInView = _lastIndexInView ;
		}
		
		private function setIndexInView(firstIndex:int, lastIndex:int):void {
			if ((_firstIndexInView == firstIndex) && (_lastIndexInView == lastIndex) )
				return;
			_firstIndexInView = firstIndex;
			_lastIndexInView = lastIndex;
			//dispatchEvent(new Event("indexInViewChanged"));
		}
	}
}