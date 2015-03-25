/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/
 * */
package starling.extensions.sap {
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;

	public class ParticlePrototype {

		// Atlas
		public var atlas:ParticleTextureAtlas;

		// Blend
		private var blendSource:String;
		private var blendDestination:String;

		// If <code>true</code>, then play animation
		private var animated:Boolean;

		// Size
		private var width:Number;
		private var height:Number;

		// Key frames of animation.
		private var timeKeys:Vector.<Number> = new Vector.<Number>();
		private var rotationKeys:Vector.<Number> = new Vector.<Number>();
		private var scaleXKeys:Vector.<Number> = new Vector.<Number>();
		private var scaleYKeys:Vector.<Number> = new Vector.<Number>();
		private var redKeys:Vector.<Number> = new Vector.<Number>();
		private var greenKeys:Vector.<Number> = new Vector.<Number>();
		private var blueKeys:Vector.<Number> = new Vector.<Number>();
		private var alphaKeys:Vector.<Number> = new Vector.<Number>();
		private var keysCount:int = 0;

		public function ParticlePrototype(width:Number, height:Number, atlas:ParticleTextureAtlas, animated:Boolean = false, blendSource:String = "sourceAlpha", blendDestination:String = "oneMinusSourceAlpha") {
			this.width = width;
			this.height = height;
			this.atlas = atlas;
			this.animated = animated;
			this.blendSource = blendSource;
			this.blendDestination = blendDestination;
		}

		public function addKey(time:Number, rotation:Number = 0, scaleX:Number = 1, scaleY:Number = 1, red:Number = 1, green:Number = 1, blue:Number = 1, alpha:Number = 1):void {
			var lastIndex:int = keysCount - 1;
			if (keysCount > 0 && time <= timeKeys[lastIndex]) throw new Error("Keys must be successively.");
			timeKeys[keysCount] = time;
			rotationKeys[keysCount] = rotation;
			scaleXKeys[keysCount] = scaleX;
			scaleYKeys[keysCount] = scaleY;
			redKeys[keysCount] = red;
			greenKeys[keysCount] = green;
			blueKeys[keysCount] = blue;
			alphaKeys[keysCount] = alpha;
			keysCount++;
		}

		public function createParticle(effect:ParticleEffect, time:Number, position:Vector3D, rotation:Number = 0, scaleX:Number = 1, scaleY:Number = 1, alpha:Number = 1, firstFrame:int = 0):void {
			var b:int = keysCount - 1;
			if (atlas.diffuse.base != null && keysCount > 1 && time >= timeKeys[0] && time < timeKeys[b]) {

				for (b = 1; b < keysCount; b++) {
					if (time < timeKeys[b]) {
						var systemScale:Number = effect.system.scale;
						var effectScale:Number = effect.scale;

						//localToCameraTransform;
						var wind:Vector3D = effect.system.wind;
						var gravity:Vector3D = effect.system.gravity;
						// Interpolation
						var a:int = b - 1;
						var t:Number = (time - timeKeys[a]) / (timeKeys[b] - timeKeys[a]);
						// Frame calculation
						var pos:int = firstFrame + (animated ? time * atlas.fps : 0);
						if (atlas.loop) {
							pos = pos % atlas.rangeLength;
							if (pos < 0) pos += atlas.rangeLength;
						} else {
							if (pos < 0) pos = 0;
							if (pos >= atlas.rangeLength) pos = atlas.rangeLength - 1;
						}
						pos += atlas.rangeBegin;
						var col:int = pos % atlas.columnsCount;
						var row:int = pos / atlas.columnsCount;
						// Particle creation
						var particle:Particle = Particle.create();
						particle.diffuse = atlas.diffuse.base;
						particle.opacity = (atlas.opacity != null) ? atlas.opacity.base : null;
						particle.blendSource = blendSource;
						particle.blendDestination = blendDestination;
						var cx:Number = effect.keyPosition.x + position.x * effectScale;
						var cy:Number = effect.keyPosition.y + position.y * effectScale;
						var cz:Number = effect.keyPosition.z + position.z * effectScale;

						var transform:Matrix3D = effect.system.transformationMatrix3D;
						transformVector(transform, cx, cy, cz, TEMP_VECTOR);

						particle.x = TEMP_VECTOR.x;
						particle.y = TEMP_VECTOR.y;
						particle.z = TEMP_VECTOR.z;

						var rot:Number = rotationKeys[a] + (rotationKeys[b] - rotationKeys[a]) * t;
						particle.rotation = (scaleX * scaleY > 0) ? (rotation + rot) : (rotation - rot);
						var systemScaleX:Number = systemScale * effectScale * scaleX * (scaleXKeys[a] + (scaleXKeys[b] - scaleXKeys[a]) * t);
						var systemScaleY:Number = systemScale * effectScale * scaleY * (scaleYKeys[a] + (scaleYKeys[b] - scaleYKeys[a]) * t);
						particle.width = width * systemScaleX;
						particle.height = height * systemScaleY;
						particle.originX = atlas.originX;
						particle.originY = atlas.originY;
						particle.uvScaleX = 1 / atlas.columnsCount;
						particle.uvScaleY = 1 / atlas.rowsCount;
						particle.uvOffsetX = col / atlas.columnsCount;
						particle.uvOffsetY = row / atlas.rowsCount;
						particle.red = redKeys[a] + (redKeys[b] - redKeys[a]) * t;
						particle.green = greenKeys[a] + (greenKeys[b] - greenKeys[a]) * t;
						particle.blue = blueKeys[a] + (blueKeys[b] - blueKeys[a]) * t;
						particle.alpha = alpha * (alphaKeys[a] + (alphaKeys[b] - alphaKeys[a]) * t);
						particle.next = effect.particleList;
						effect.particleList = particle;
						break;
					}
				}
			}
		}

		public static const RAW_DATA_CONTAINER:Vector.<Number> = new Vector.<Number>(16);
		private static const TEMP_VECTOR:Vector3D = new Vector3D();

		public static function transformVector(matrix:Matrix3D, vx:Number, vy:Number, vz:Number, result:Vector3D = null):Vector3D {
			if (!result) result = new Vector3D();
			var raw:Vector.<Number> = RAW_DATA_CONTAINER;
			matrix.copyRawDataTo(raw);
			var a:Number = raw[0];
			var e:Number = raw[1];
			var i:Number = raw[2];
			var m:Number = raw[3];
			var b:Number = raw[4];
			var f:Number = raw[5];
			var j:Number = raw[6];
			var n:Number = raw[7];
			var c:Number = raw[8];
			var g:Number = raw[9];
			var k:Number = raw[10];
			var o:Number = raw[11];
			var d:Number = raw[12];
			var h:Number = raw[13];
			var l:Number = raw[14];
			var p:Number = raw[15];

			var x:Number = vx;
			var y:Number = vy;
			var z:Number = vz;
			result.x = a * x + b * y + c * z + d;
			result.y = e * x + f * y + g * z + h;
			result.z = i * x + j * y + k * z + l;
			result.w = m * x + n * y + o * z + p;
			return result;
		}

		public function get lifeTime():Number {
			var lastIndex:int = keysCount - 1;
			return timeKeys[lastIndex];
		}

	}
}
