using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class Depth : ScriptableRendererFeature
{
    [Serializable]
    public class Settings
    {
        //默认在transparent后
        public RenderPassEvent passEvent = RenderPassEvent.AfterRenderingSkybox;
        public Material material;//使用的材质
    }

    public Settings setting = new Settings();
    
    class DepthPass : ScriptableRenderPass
    {
        private Material _material;

        public DepthPass(Material material)
        {
            _material = material;
        }

        // This method is called before executing the render pass.
        // It can be used to configure render targets and their clear state. Also to create temporary render target textures.
        // When empty this render pass will render to the active camera render target.
        // You should never call CommandBuffer.SetRenderTarget. Instead call <c>ConfigureTarget</c> and <c>ConfigureClear</c>.
        // The render pipeline will ensure target setup and clearing happens in a performant manner.
        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            // ConfigureTarget();
            // ConfigureTarget(renderingData.cameraData.renderer.cameraColorTarget, desc.depthStencilFormat, desc.width, desc.height, 1, true);
            ConfigureTarget(renderingData.cameraData.renderer.cameraColorTarget);
        }

        // Here you can implement the rendering logic.
        // Use <c>ScriptableRenderContext</c> to issue drawing commands or execute command buffers
        // https://docs.unity3d.com/ScriptReference/Rendering.ScriptableRenderContext.html
        // You don't have to call ScriptableRenderContext.submit, the render pipeline will call it at specific points in the pipeline.
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CommandBuffer cmd = CommandBufferPool.Get("Depth");
            
            // RenderTextureDescriptor desc = renderingData.cameraData.cameraTargetDescriptor;
            // int de = Shader.PropertyToID("_DepthTex");
            // cmd.GetTemporaryRT(de, desc);
            // cmd.Blit(depthAttachment, de);
            
            cmd.Blit(depthAttachment, colorAttachment, _material,0);
            
            context.ExecuteCommandBuffer(cmd);

            CommandBufferPool.Release(cmd);
        }

        // Cleanup any allocated resources that were created during the execution of this render pass.
        public override void OnCameraCleanup(CommandBuffer cmd)
        {
        }
    }

    DepthPass _depthPass;

    /// <inheritdoc/>
    public override void Create()
    {

        _depthPass = new DepthPass(setting.material);

        // Configures where the render pass should be injected.
        _depthPass.renderPassEvent = RenderPassEvent.AfterRenderingSkybox;
    }

    // Here you can inject one or multiple render passes in the renderer.
    // This method is called when setting up the renderer once per-camera.
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(_depthPass);
    }
}


