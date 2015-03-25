/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/
 * */
package starling.extensions.sap {
	import com.adobe.utils.AGALMiniAssembler;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DBlendFactor;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.Program3D;
	import flash.display3D.VertexBuffer3D;
	import flash.display3D.textures.TextureBase;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.utils.getTimer;

	import starling.core.RenderSupport;
	import starling.core.Starling;
	import starling.display.Sprite;

	public class ParticleSystem extends Sprite {

		static private const limit:int = 31;
		static private var vertexBuffer:VertexBuffer3D;
		static private var indexBuffer:IndexBuffer3D;
		static private var diffuseProgram:Program3D;
		static private var opacityProgram:Program3D;
		static private var diffuseBlendProgram:Program3D;
		static private var opacityBlendProgram:Program3D;
		private var sAssembler:AGALMiniAssembler = new AGALMiniAssembler();
		private var mvp:Matrix3D = new Matrix3D();

		private var vertexConstants:Vector.<Number> = new Vector.<Number>();
		private var vertexConstantsRegistersCount:int = 0;

		public var gravity:Vector3D = new Vector3D(0, 0, -1);
		public var wind:Vector3D = new Vector3D();
		public var sortParticlesByZ:Boolean = false;

		public var scale:Number = 1;
		public var effectList:ParticleEffect;

		private var diffuse:TextureBase = null;
		private var opacity:TextureBase = null;
		private var blendSource:String = null;
		private var blendDestination:String = null;
		private var counter:int;

		public function ParticleSystem() {
			super();
		}

		private var pause:Boolean = false;
		private var stopTime:Number;
		private var subtractiveTime:Number = 0;

		public function stop():void {
			if (!pause) {
				stopTime = getTimer() * 0.001;
				pause = true;
			}
		}

		public function play():void {
			if (pause) {
				subtractiveTime += getTimer() * 0.001 - stopTime;
				pause = false;
			}
		}

		public function prevFrame():void {
			stopTime -= 0.001;
		}

		public function nextFrame():void {
			stopTime += 0.001;
		}

		public function addEffect(effect:ParticleEffect):ParticleEffect {
			// Checking on belonging
			if (effect.system != null) throw new Error("Cannot add the same effect twice.");
			// Set parameters
			effect.startTime = getTime();
			effect.system = this;
			effect.setPositionKeys(0);
			effect.setDirectionKeys(0);
			// Add
			effect.nextInSystem = effectList;
			effectList = effect;
			return effect;
		}

		public function getEffectByName(name:String):ParticleEffect {
			for (var effect:ParticleEffect = effectList; effect != null; effect = effect.nextInSystem) {
				if (effect.name == name) return effect;
			}
			return null;
		}

		public function getTime():Number {
			return pause ? (stopTime - subtractiveTime) : (getTimer() * 0.001 - subtractiveTime);
		}


		override public function render(support:RenderSupport, parentAlpha:Number):void {
			support.finishQuadBatch();

			// Create geometry and program
			if (vertexBuffer == null) createAndUpload(Starling.context);
			// Loop items
			var visibleEffectList:ParticleEffect;
			var time:Number = getTime();
			for (var effect:ParticleEffect = effectList, prev:ParticleEffect = null; effect != null;) {
				// Check if actual
				var effectTime:Number = time - effect.startTime;
				if (effectTime <= effect.lifeTime) {
					if (effect.calculate(effectTime)) {
						// Add
						if (effect.particleList != null) {
							effect.next = visibleEffectList;
							visibleEffectList = effect;
						}
						prev = effect;
						effect = effect.nextInSystem;
					} else {
						// Removing
						if (prev != null) {
							prev.nextInSystem = effect.nextInSystem;
							effect = prev.nextInSystem;
						} else {
							effectList = effect.nextInSystem;
							effect = effectList;
						}
					}
				} else {
					// Removing
					if (prev != null) {
						prev.nextInSystem = effect.nextInSystem;
						effect = prev.nextInSystem;
					} else {
						effectList = effect.nextInSystem;
						effect = effectList;
					}
				}
			}
			// Gather draws
			if (visibleEffectList != null) {
				if (visibleEffectList.next != null) {
					drawConflictEffects(support, visibleEffectList);
				} else {
					drawParticleList(support, visibleEffectList.particleList);
					visibleEffectList.particleList = null;
				}
				flush(support);
				diffuse = null;
				opacity = null;
				blendSource = null;
				blendDestination = null;
			}

			var context:Context3D = Starling.context;
			context.setTextureAt(0, null);
			context.setTextureAt(1, null);
		}

		private function createAndUpload(context:Context3D):void {
			var vertices:Vector.<Number> = new Vector.<Number>();
			var indices:Vector.<uint> = new Vector.<uint>();
			for (var i:int = 0; i < limit; i++) {
				vertices.push(
						0, 0, i * 4,
						0, 1, i * 4,
						1, 0, i * 4,
						1, 1, i * 4);
				indices.push(i * 4, i * 4 + 1, i * 4 + 2, i * 4 + 1, i * 4 + 3, i * 4 + 2);
			}
			vertexBuffer = context.createVertexBuffer(limit * 4, 3);
			vertexBuffer.uploadFromVector(vertices, 0, limit * 4);
			indexBuffer = context.createIndexBuffer(limit * 6);
			indexBuffer.uploadFromVector(indices, 0, limit * 6);
			var vertexProgram:String =
				// Pivot
					"mov vt2, vc[va0.z]\n" + // originX, originY, width, height
					"sub vt0.z, va0.x, vt2.x\n" +
					"sub vt0.w, va0.y, vt2.y\n" +
				// Width and height
					"mul vt0.z, vt0.z, vt2.z\n" +
					"mul vt0.w, vt0.w, vt2.w\n" +
				// Rotation
					"mov vt2, vc[va0.z+1]\n" + // x, y, sin, cos
					"mul vt1.z, vt0.z, vt2.w\n" + // x*cos
					"mul vt1.w, vt0.w, vt2.z\n" + // y*sin
					"sub vt0.x, vt1.z, vt1.w\n" + // X
					"mul vt1.z, vt0.z, vt2.z\n" + // x*sin
					"mul vt1.w, vt0.w, vt2.w\n" + // y*cos
					"add vt0.y, vt1.z, vt1.w\n" + // Y
				// Translation
					"add vt0.x, vt0.x, vt2.x\n" +
					"add vt0.y, vt0.y, vt2.y\n" +
					"mov vt0.zw, va0.ww\n" +
				// Projection
//					"m44 op, vt0, vc124\n" +
					"dp4 op.x, vt0, vc124\n" +
					"dp4 op.y, vt0, vc125\n" +
					"dp4 op.z, vt0, vc126\n" +
					"dp4 op.w, vt0, vc127\n" +
				// UV correction and passing out
					"mov vt2, vc[va0.z+2]\n" + // uvScaleX, uvScaleY, uvOffsetX, uvOffsetY
					"mul vt1.x, va0.x, vt2.x\n" +
					"mul vt1.y, va0.y, vt2.y\n" +
					"add vt1.x, vt1.x, vt2.z\n" +
					"add vt1.y, vt1.y, vt2.w\n" +
					"mov v0, vt1.xy\n" +
				// Passing color
					"mov v1, vc[va0.z+3]\n";// red, green, blue, alpha

			var fragmentDiffuseProgram:String =
					"tex ft0, v0, fs0 <2d,clamp,linear,miplinear>\n" +
					"mul ft0, ft0, v1\n" +

					"mov oc, ft0\n";

			var fragmentOpacityProgram:String =
					"tex ft0, v0, fs0 <2d,clamp,linear,miplinear>\n" +
					"tex ft1, v0, fs1 <2d,clamp,linear,miplinear>,dxt1\n" +
					"mov ft0.w, ft1.x\n" +
					"mul ft0, ft0, v1\n" +

					"mov oc, ft0\n";

			var fragmentDiffuseBlendProgram:String =
					"tex ft0, v0, fs0 <2d,clamp,linear,miplinear>\n" +
					"mul ft0, ft0, v1\n" +

					"mov oc, ft0\n";

			var fragmentOpacityBlendProgram:String =
					"tex ft0, v0, fs0 <2d,clamp,linear,miplinear>\n" +
					"tex ft1, v0, fs1 <2d,clamp,linear,miplinear,dxt1>\n" +
					"mov ft0.w, ft1.x\n" +
					"mul ft0, ft0, v1\n" +

					"mov oc, ft0";
			diffuseProgram = context.createProgram();
			opacityProgram = context.createProgram();
			diffuseBlendProgram = context.createProgram();
			opacityBlendProgram = context.createProgram();

			diffuseProgram.upload(
					sAssembler.assemble(Context3DProgramType.VERTEX, vertexProgram),
					sAssembler.assemble(Context3DProgramType.FRAGMENT, fragmentDiffuseProgram));

			opacityProgram.upload(
					sAssembler.assemble(Context3DProgramType.VERTEX, vertexProgram),
					sAssembler.assemble(Context3DProgramType.FRAGMENT, fragmentOpacityProgram));

			diffuseBlendProgram.upload(
					sAssembler.assemble(Context3DProgramType.VERTEX, vertexProgram),
					sAssembler.assemble(Context3DProgramType.FRAGMENT, fragmentDiffuseBlendProgram));

			opacityBlendProgram.upload(
					sAssembler.assemble(Context3DProgramType.VERTEX, vertexProgram),
					sAssembler.assemble(Context3DProgramType.FRAGMENT, fragmentOpacityBlendProgram));
		}


		private function flush(support:RenderSupport):void {
			var context:Context3D = Starling.context;

			var numTriangles:Number = counter << 1;
			var program:Program3D;
			if (blendDestination == Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA) {
				program = (opacity != null) ? opacityProgram : diffuseProgram;
			} else {
				program = (opacity != null) ? opacityBlendProgram : diffuseBlendProgram;
			}
			context.setProgram(program);

			// Set streams
			context.setVertexBufferAt(0, vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
			context.setBlendFactors(blendSource, blendDestination);

			context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 0, vertexConstants, vertexConstantsRegistersCount);
			// Set constants
			mvp.copyFrom(support.mvpMatrix3D);
			context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 124, mvp, true);

			context.setTextureAt(0, diffuse);
			if (opacity != null) context.setTextureAt(1, opacity);

			support.raiseDrawCount();

			context.drawTriangles(indexBuffer, 0, numTriangles);
			counter = 0;
		}

		private function drawParticleList(support:RenderSupport, list:Particle):void {
			if (sortParticlesByZ && list.next != null) list = sortParticleList(list);
			// Gather draws
			var last:Particle;
			for (var particle:Particle = list; particle != null; particle = particle.next) {
				if (counter >= limit || particle.diffuse != diffuse || particle.opacity != opacity || particle.blendSource != blendSource || particle.blendDestination != blendDestination) {
					if (counter > 0) {
						flush(support);
					}

					diffuse = particle.diffuse;
					opacity = particle.opacity;
					blendSource = particle.blendSource;
					blendDestination = particle.blendDestination;
					counter = 0;
					vertexConstantsRegistersCount = 0;
					vertexConstants.length = 0;
				}
				// Write constants
				var offset:int = counter << 2;

				setVertexConstantsFromNumbers(offset++, particle.originX, particle.originY, particle.width, particle.height);
				setVertexConstantsFromNumbers(offset++, particle.x, particle.y, Math.sin(particle.rotation), Math.cos(particle.rotation));
				setVertexConstantsFromNumbers(offset++, particle.uvScaleX, particle.uvScaleY, particle.uvOffsetX, particle.uvOffsetY);
				setVertexConstantsFromNumbers(offset++, particle.red, particle.green, particle.blue, particle.alpha);

				counter++;
				last = particle;
			}
			// Send to the collector
			last.next = Particle.collector;
			Particle.collector = list;
		}

		private function setVertexConstantsFromNumbers(firstRegister:int, x:Number, y:Number, z:Number, w:Number = 1):void {
			if (uint(firstRegister) > 127) throw new Error("Register index " + firstRegister + " is out of bounds.");
			var offset:int = firstRegister << 2;
			if (firstRegister + 1 > vertexConstantsRegistersCount) {
				vertexConstantsRegistersCount = firstRegister + 1;
				vertexConstants.length = vertexConstantsRegistersCount << 2;
			}
			vertexConstants[offset] = x;
			offset++;
			vertexConstants[offset] = y;
			offset++;
			vertexConstants[offset] = z;
			offset++;
			vertexConstants[offset] = w;
		}

		private static function sortParticleList(list:Particle):Particle {
			var left:Particle = list;
			var right:Particle = list.next;
			while (right != null && right.next != null) {
				list = list.next;
				right = right.next.next;
			}
			right = list.next;
			list.next = null;
			if (left.next != null) {
				left = sortParticleList(left);
			}
			if (right.next != null) {
				right = sortParticleList(right);
			}
			var flag:Boolean = left.z > right.z;
			if (flag) {
				list = left;
				left = left.next;
			} else {
				list = right;
				right = right.next;
			}
			var last:Particle = list;
			while (true) {
				if (left == null) {
					last.next = right;
					return list;
				} else if (right == null) {
					last.next = left;
					return list;
				}
				if (flag) {
					if (left.z > right.z) {
						last = left;
						left = left.next;
					} else {
						last.next = right;
						last = right;
						right = right.next;
						flag = false;
					}
				} else {
					if (right.z > left.z) {
						last = right;
						right = right.next;
					} else {
						last.next = left;
						last = left;
						left = left.next;
						flag = true;
					}
				}
			}
			return null;
		}

		private function drawConflictEffects(support:RenderSupport, effectList:ParticleEffect):void {
			var particleList:Particle;
			for (var effect:ParticleEffect = effectList; effect != null; effect = next) {
				var next:ParticleEffect = effect.next;
				effect.next = null;
				var last:Particle = effect.particleList;
				while (last.next != null) last = last.next;
				last.next = particleList;
				particleList = effect.particleList;
				effect.particleList = null;
			}
			drawParticleList(support, particleList);
		}
	}
}
