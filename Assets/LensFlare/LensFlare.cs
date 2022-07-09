using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class LensFlare : ScriptableRendererFeature
{
    public Material material;
    public Mesh mesh;
    class LensFlarePass : ScriptableRenderPass
    {
        private Material _material;
        private Mesh _mesh;

        public LensFlarePass(Material material, Mesh mesh)
        {
            _material = material;
            _mesh = mesh;
        }
        // This method is called before executing the render pass.
        // It can be used to configure render targets and their clear state. Also to create temporary render target textures.
        // When empty this render pass will render to the active camera render target.
        // You should never call CommandBuffer.SetRenderTarget. Instead call <c>ConfigureTarget</c> and <c>ConfigureClear</c>.
        // The render pipeline will ensure target setup and clearing happens in a performant manner.
        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
        }

        // Here you can implement the rendering logic.
        // Use <c>ScriptableRenderContext</c> to issue drawing commands or execute command buffers
        // https://docs.unity3d.com/ScriptReference/Rendering.ScriptableRenderContext.html
        // You don't have to call ScriptableRenderContext.submit, the render pipeline will call it at specific points in the pipeline.
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CommandBuffer cmd = CommandBufferPool.Get("LensFlarePass");

            // Get the Camera data from the renderingData argument.
            Camera camera = renderingData.cameraData.camera; 
            // Set the projection matrix so that Unity draws the quad in screen space
            cmd.SetViewProjectionMatrices(Matrix4x4.identity, Matrix4x4.identity); 
            // Add the scale variable, use the Camera aspect ration for the y coordinate
            Vector3 scale = new Vector3(1, camera.aspect, 1); 
            // Draw a quad for each Light, at the screen space position of the Light.
            foreach (VisibleLight visibleLight in renderingData.lightData.visibleLights)
            {
                Light light = visibleLight.light;
                // Convert the position of each Light from world to viewport point.
                Vector3 position =
                    camera.WorldToViewportPoint(light.transform.position) * 2 - Vector3.one;
                // Set the z coordinate of the quads to 0 so that Uniy draws them on the same plane.
                position.z = 0;
                // Change the Matrix4x4 argument in the cmd.DrawMesh method to use the position and
                // the scale variables.
                cmd.DrawMesh(_mesh, Matrix4x4.TRS(position, Quaternion.identity, scale),
                    _material, 0, 0);
            }
            //The Renderer Feature draws the quad in the Scene,but at this point it's just black.
            //This is because the Universal Render Pipeline/Unlit shader has multiple passes,
            //and one of them paints the quad black. To change this behavior,
            //use the cmd.DrawMesh method overload that accepts the shaderPass argument, and specify shader pass 0:
            cmd.DrawMesh(_mesh, Matrix4x4.identity, _material, 0, 0);
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }

        // Cleanup any allocated resources that were created during the execution of this render pass.
        public override void OnCameraCleanup(CommandBuffer cmd)
        {
        }
    }

    private LensFlarePass _lensFlarePass;

    /// <inheritdoc/>
    public override void Create()
    {
        _lensFlarePass = new LensFlarePass(material, mesh);

        // Configures where the render pass should be injected.
        // _lensFlarePass.renderPassEvent = RenderPassEvent.AfterRenderingOpaques;
        // Draw the lens flare effect after the skybox.
        _lensFlarePass.renderPassEvent = RenderPassEvent.AfterRenderingSkybox;
    }

    // Here you can inject one or multiple render passes in the renderer.
    // This method is called when setting up the renderer once per-camera.
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (material != null && mesh != null)
        {
            
            renderer.EnqueuePass(_lensFlarePass);
        }
    }
}


