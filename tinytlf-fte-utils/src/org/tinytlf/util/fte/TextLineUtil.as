package org.tinytlf.util.fte
{
	import flash.display.DisplayObject;
	import flash.geom.*;
	import flash.text.engine.*;
	import flash.utils.Dictionary;
	
	public class TextLineUtil
	{
		/**
		 * Returns the index of the atom at a particular point. If the point
		 * is outside the 
		 */
		public static function getAtomIndexAtPoint(line:TextLine, stageCoords:Point):int
		{
			var index:int = line.getAtomIndexAtPoint(stageCoords.x, stageCoords.y);
			
			if (index < 0)
			{
				var bounds:Rectangle = line.getBounds(line.stage);
				var center:Point = bounds.topLeft.clone();
				center.offset(bounds.width * .5, bounds.height * .5);
				
				if(stageCoords.y < bounds.y)
					return 0;
				if(stageCoords.y > bounds.y + bounds.height)
					return line.atomCount - 1;
				
				index = (stageCoords.x < center.x) ? 0 : line.atomCount - 1;
			}
			
			var atomIncrement:int = getAtomSide(line, stageCoords) ? 0 : 1;
			
			return Math.max(index + atomIncrement, 0);
		}
		
		/**
		 * Finds which side of the atom the point is on.
		 * @returns true for left, false for right.
		 */
		public static function getAtomSide(line:TextLine, stageCoords:Point):Boolean
		{
			var atomIndex:int = line.getAtomIndexAtPoint(stageCoords.x, 1);
			
			if(atomIndex < 0)
				return true;
			
			var center:Number = line.getAtomCenter(atomIndex);
			var pt:Point = line.localToGlobal(new Point(center));
			
			return pt.x > stageCoords.x;
		}
		
		private static const defaultWordBoundaryPattern:RegExp = /\W+|\b[^\W﷯]*/;
		private static const nonWordPattern:RegExp = /\W/;
		
		/**
		 * Finds the next/prev word boundary specified by the direction and the
		 * boundaryPattern. If no boundary pattern is specified, the default 
		 * is used, which matches non-word characters or graphic characters.
		 */
		public static function getAtomWordBoundary(line:TextLine, atomIndex:int, 
												   left:Boolean = true, boundaryPattern:RegExp = null):int
		{
			if(!boundaryPattern)
				boundaryPattern = defaultWordBoundaryPattern;
			
			if(atomIndex >= line.atomCount)
				atomIndex = line.atomCount - 1;
			else if(atomIndex < 0)
				atomIndex = 0;
			
			var rawText:String = line.textBlock.content.rawText;
			var adjustedIndex:int = line.getAtomTextBlockBeginIndex(atomIndex);
			
			if(nonWordPattern.test(rawText.charAt(adjustedIndex)))
			{
				return atomIndex;
			}
			else
			{
				var text:String = left ?
					rawText.slice(0, adjustedIndex).split("").reverse().join("") :
					rawText.slice(adjustedIndex + 1, rawText.length);
				
				var match:Array = boundaryPattern.exec(text);
				if(match)
				{
					var str:String = String(match[0]);
					atomIndex += nonWordPattern.test(str) ? 0 : str.length * (left ? -1 : 1);
				}
			}
			
			return Math.max(atomIndex, 0);
		}
		
		/**
		 * Recursively drills down into the ContentElement of the TextLine's 
		 * TextBlock to return the exact element at the specified atomIndex.
		 */
		public static function getElementAtAtomIndex(line:TextLine, atomIndex:int):ContentElement
		{
			if(atomIndex < 0)
				return null;
			
			var block:TextBlock = line.textBlock;
			var blockBeginIndex:int = line.textBlockBeginIndex;
			var content:ContentElement = block.content;
			var charIndex:int = blockBeginIndex - content.textBlockBeginIndex + atomIndex;
			
			// If you recycle TextBlocks, funky things will happen.
			// For example, the blockBeginIndex here will report a value of 
			// 0xFFFFFFFF, obviously erroneous. We have a second check here to 
			// stop this from throwing RTEs, but honestly, it's likely you'll
			// just get an RTE somewhere else, because the returned 
			// contentElement will be a GroupElement here instead of a 
			// TextElement or GraphicElement like you were expecting.
			// .poop.
			
			while(content is GroupElement && charIndex < block.content.rawText.length)
			{
				content = GroupElement(content).getElementAtCharIndex(charIndex);
				charIndex = blockBeginIndex - content.textBlockBeginIndex + atomIndex;
			}
			
			return content;
		}
		
		/**
		 * Returns a Vector of ContentElements which are rendered in this 
		 * TextLine. This can only return the elements that have specified
		 * eventMirrors, so it's not guaranteed to be every ContentElement,
		 * and the elements won't necessarily be in order.
		 */
		public static function getContentElements(line:TextLine):Vector.<ContentElement>
		{
			var dict:Dictionary = new Dictionary();
			var tlmrs:Vector.<TextLineMirrorRegion> = line.mirrorRegions;
			
			if(!tlmrs)
				return elements;
			
			var n:int = tlmrs.length;
			
			for(var i:int = 0; i < n; ++i)
			{
				dict[tlmrs[i].element] = true;
			}
			
			var elements:Vector.<ContentElement> = new <ContentElement>[];
			for(var element:* in dict)
			{
				elements.push(ContentElement(element));
			}
			
			return elements;
		}
		
		public static function hasLineBreak(line:TextLine):Boolean
		{
			if(line.atomCount <= 1)
				return false;
			
			//Check to see if we have a line break graphic at the end of the TextLine
			var graphicIndex:int = line.atomCount - 1;
			var dObj:DisplayObject = line.getAtomGraphic(graphicIndex);
			if(!dObj)
				return false;
			
			//We have some kind of graphic at the end, is it a line break?
			var g:GraphicElement = GraphicElement(getElementAtAtomIndex(line, graphicIndex));
			return g.userData === TextLineUtil.getSingletonMarker('lineBreak');
		}
		
		private static const singletons:Object = {};
		
		/**
		 * Central repository for storing/retrieving marker objects for text 
		 * layout. The technique is useful for layout, where the userData
		 * properties of the ContentElement can mark the element for special
		 * layout provisions.
		 */
		public static function getSingletonMarker(name:String):Object
		{
			if(singletons.hasOwnProperty(name))
				return singletons[name];
			
			return singletons[name] = {};
		}
	}
}