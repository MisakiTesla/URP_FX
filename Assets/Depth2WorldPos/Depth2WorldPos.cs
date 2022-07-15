using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class Depth2WorldPos : ScriptableRendererFeature
{
    [Serializable]
    public class Settings
    {
        //默认在transparent后
        public RenderPassEvent passEvent = RenderPassEvent.AfterRenderingTransparents;
        public Material material;//使用的材质
    }

    public Settings setting = new Settings();
    
    class Depth2WorldPass : ScriptableRenderPass
    {
        private Material _material;
        
        public Depth2WorldPass(Material material)
        {
            _material = material;
        }
        
        public void SetUp(RenderTargetIdentifier colorIdentifier)
        {
        }
        
        // This method is called before executing the render pass.
        // It can be used to configure render targets and their clear state. Also to create temporary render target textures.
        // When empty this render pass will render to the active camera render target.
        // You should never call CommandBuffer.SetRenderTarget. Instead call <c>ConfigureTarget</c> and <c>ConfigureClear</c>.
        // The render pipeline will ensure target setup and clearing happens in a performant manner.
        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            // ConfigureTarget();
            // Debug.Log("OnCameraSetup");
            // _depthId = renderingData.cameraData.renderer.cameraDepthTarget;

            // ConfigureTarget(renderingData.cameraData.renderer.cameraColorTarget, desc.depthStencilFormat, desc.width, desc.height, 1, true);
            ConfigureTarget(renderingData.cameraData.renderer.cameraColorTarget);


            
        }

        // Here you can implement the rendering logic.
        // Use <c>ScriptableRenderContext</c> to issue drawing commands or execute command buffers
        // https://docs.unity3d.com/ScriptReference/Rendering.ScriptableRenderContext.html
        // You don't have to call ScriptableRenderContext.submit, the render pipeline will call it at specific points in the pipeline.
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CommandBuffer cmd = CommandBufferPool.Get("Depth2WorldPos");
            
            int tempRT = Shader.PropertyToID("Depth2WorldPosTempRT");
            RenderTextureDescriptor desc = renderingData.cameraData.cameraTargetDescriptor;
            // Debug.Log();
            // 1 射线法
            // 相似三角形
            // 构建camera到 深度的射线向量，存储在矩阵里，用于重建世界坐标
            {
                Camera cam = renderingData.cameraData.camera;

                float height = cam.nearClipPlane * Mathf.Tan(Mathf.Deg2Rad * cam.fieldOfView * 0.5f);
                Vector3 up = cam.transform.up * height;
                Vector3 right = cam.transform.right * height * cam.aspect;
                Vector3 forward = cam.transform.forward * cam.nearClipPlane;
                Vector3 ButtomLeft = forward - right - up;//camera到near平面四角的 向量

                float scale = ButtomLeft.magnitude / cam.nearClipPlane;

                ButtomLeft.Normalize();
                ButtomLeft *= scale;
                Vector3 ButtomRight = forward + right - up;
                ButtomRight.Normalize();
                ButtomRight *= scale;
                Vector3 TopRight = forward + right + up;
                TopRight.Normalize();
                TopRight *= scale;
                Vector3 TopLeft = forward - right + up;
                TopLeft.Normalize();
                TopLeft *= scale;

                Matrix4x4 MATRIX = new Matrix4x4();

                MATRIX.SetRow(0, ButtomLeft);
                MATRIX.SetRow(1, ButtomRight);
                MATRIX.SetRow(2, TopRight);
                MATRIX.SetRow(3, TopLeft);

                _material.SetMatrix("Matrix", MATRIX);
            }
            // 2 采样深度图得到NDC坐标，然后直接乘一个VP矩阵的逆就是世界坐标了（记得要除个.w）
            
            
            cmd.GetTemporaryRT(tempRT, desc);
            cmd.Blit(colorAttachment, tempRT, _material,0);
            cmd.Blit(tempRT, colorAttachment);
            context.ExecuteCommandBuffer(cmd);

            CommandBufferPool.Release(cmd);
            cmd.ReleaseTemporaryRT(tempRT);

        }

        // Cleanup any allocated resources that were created during the execution of this render pass.
        public override void OnCameraCleanup(CommandBuffer cmd)
        {
        }
    }

    Depth2WorldPass _depth2WorldPass;

    /// <inheritdoc/>
    public override void Create()
    {
        _depth2WorldPass = new Depth2WorldPass(setting.material);

        // Configures where the render pass should be injected.
        _depth2WorldPass.renderPassEvent = RenderPassEvent.AfterRenderingOpaques;
    }

    // Here you can inject one or multiple render passes in the renderer.
    // This method is called when setting up the renderer once per-camera.
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        // Debug.Log("AddRenderPasses");
        if (setting.material)
        {
            renderer.EnqueuePass(_depth2WorldPass);
        }
    }
}


