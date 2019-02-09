package com.eserviceplatform.mobile.camerasupport.plugin.view;

import androidx.core.view.ViewCompat;

import android.view.Surface;
import android.view.SurfaceHolder;
import android.view.View;

import com.eserviceplatform.mobile.camerasupport.plugin.base.PreviewImpl;


import java.util.ArrayList;
import java.util.List;

import io.flutter.view.FlutterView;

public class FlutterSurfaceView extends PreviewImpl {
    List<Surface> surfaces = new ArrayList<>();

    final FlutterView mSurfaceView;
    FlutterView.SurfaceTextureEntry surfaceTextureEntry;

    public FlutterSurfaceView(FlutterView view, FlutterView.SurfaceTextureEntry _surfaceTextureEntry) {
        mSurfaceView = view;
        final SurfaceHolder holder = mSurfaceView.getHolder();
        surfaceTextureEntry = _surfaceTextureEntry;
        //noinspection deprecation
        holder.setType(SurfaceHolder.SURFACE_TYPE_PUSH_BUFFERS);
        holder.addCallback(new SurfaceHolder.Callback() {
            @Override
            public void surfaceCreated(SurfaceHolder h) {
            }

            @Override
            public void surfaceChanged(SurfaceHolder h, int format, int width, int height) {
                setSize(width, height);
                if (!ViewCompat.isInLayout(mSurfaceView)) {
                    dispatchSurfaceChanged();
                }
            }

            @Override
            public void surfaceDestroyed(SurfaceHolder h) {
                setSize(0, 0);
            }
        });
    }

    @Override
    public Surface getSurface() {

        return new Surface(surfaceTextureEntry.surfaceTexture());
    }

    @Override
    public Object getSurfaceTexture() {
        return surfaceTextureEntry.surfaceTexture();
    }

    @Override
    public SurfaceHolder getSurfaceHolder() {
        return mSurfaceView.getHolder();
    }

    @Override
    public View getView() {
        return mSurfaceView;
    }

    @Override
    public Class getOutputClass() {
        return SurfaceHolder.class;
    }

    @Override
    public void setDisplayOrientation(int displayOrientation) {
    }

    @Override
    public boolean isReady() {
        return this.mSurfaceView.getWidth() != 0 && this.mSurfaceView.getHeight() != 0;
    }
    @Override
    public  int getWidth(){
        return this.mSurfaceView.getWidth();
    }

    @Override
    public int getHeight(){
        return this.mSurfaceView.getHeight();
    }
}
