
package com.eserviceplatform.mobile.camerasupport.plugin.api.v23;;

import android.annotation.TargetApi;
import android.content.Context;
import android.graphics.ImageFormat;
import android.hardware.camera2.params.StreamConfigurationMap;

import com.eserviceplatform.mobile.camerasupport.plugin.api.v21.Camera2;
import com.eserviceplatform.mobile.camerasupport.plugin.base.AspectRatio;
import com.eserviceplatform.mobile.camerasupport.plugin.base.CameraViewImpl;
import com.eserviceplatform.mobile.camerasupport.plugin.base.Constants;
import com.eserviceplatform.mobile.camerasupport.plugin.base.PreviewImpl;
import com.eserviceplatform.mobile.camerasupport.plugin.base.SizeMap;
import com.eserviceplatform.mobile.camerasupport.plugin.base.Size;

@TargetApi(23)
public class Camera2Api23 extends Camera2 {

    public Camera2Api23(Callback callback, PreviewImpl preview, Context context) {
        super(callback, preview, context);
    }

    @Override
    protected void collectPictureSizes(SizeMap sizes, StreamConfigurationMap map) {
        // Try to get hi-res output sizes
        android.util.Size[] outputSizes = map.getHighResolutionOutputSizes(ImageFormat.JPEG);
        if (outputSizes != null) {
            for (android.util.Size size : map.getHighResolutionOutputSizes(ImageFormat.JPEG)) {
                sizes.add(new Size(size.getWidth(), size.getHeight()));
            }
        }
        if (sizes.isEmpty()) {
            super.collectPictureSizes(sizes, map);
        }
    }

}
