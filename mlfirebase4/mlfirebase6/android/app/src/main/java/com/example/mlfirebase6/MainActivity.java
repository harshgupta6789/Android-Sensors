package com.example.mlfirebase6;

//import androidx.annotation.NonNull;

import android.Manifest;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.widget.ImageView;
import android.widget.Toast;

import com.example.mlfirebase6.listeners.PictureCapturingListener;
import com.example.mlfirebase6.services.APictureCapturingService;
import com.example.mlfirebase6.services.PictureCapturingServiceImpl;

import java.util.TreeMap;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;

//import android.support.annotation.NonNull;
//import android.support.v4.app.ActivityCompat;
//import android.support.v4.content.ContextCompat;
//import android.support.v7.app.AppCompatActivity;

public class MainActivity extends FlutterActivity implements PictureCapturingListener{

    private static final String[] requiredPermissions = {
            Manifest.permission.WRITE_EXTERNAL_STORAGE,
            Manifest.permission.CAMERA,
    };
    private static final int MY_PERMISSIONS_REQUEST_ACCESS_CODE = 1;

    private ImageView uploadBackPhoto;
    private ImageView uploadFrontPhoto;

    //The capture service
    private APictureCapturingService pictureService;


    private static final String CHANNEL = "com.example.epic/epic";

    private void showToast(final String text) {
        runOnUiThread(() ->
                Toast.makeText(getApplicationContext(), text, Toast.LENGTH_SHORT).show()
        );
    }

  @Override
  public void configureFlutterEngine(FlutterEngine flutterEngine) {

    GeneratedPluginRegistrant.registerWith(flutterEngine);
//      checkPermissions();
      pictureService = PictureCapturingServiceImpl.getInstance(this);

    new MethodChannel(flutterEngine.getDartExecutor(), CHANNEL).setMethodCallHandler(
            new MethodChannel.MethodCallHandler() {
              @Override
              public void onMethodCall(MethodCall methodCall, MethodChannel.Result result) {
                if (methodCall.method.equals("Printy")) {
                    showToast("Starting capture!");
                    pictureService.startCapturing(MainActivity.this);
                  result.success("hiFormJava");

                } else {
                  result.notImplemented();
                }
              }
            }
    );
  }

    @Override
    public void onCaptureDone(String pictureUrl, byte[] pictureData) {
        if (pictureData != null && pictureUrl != null) {
            runOnUiThread(() -> {
                final Bitmap bitmap = BitmapFactory.decodeByteArray(pictureData, 0, pictureData.length);
                final int nh = (int) (bitmap.getHeight() * (512.0 / bitmap.getWidth()));
                final Bitmap scaled = Bitmap.createScaledBitmap(bitmap, 512, nh, true);
                if (pictureUrl.contains("0_pic.jpg")) {
                    uploadBackPhoto.setImageBitmap(scaled);
                } else if (pictureUrl.contains("1_pic.jpg")) {
                    uploadFrontPhoto.setImageBitmap(scaled);
                }
            });
            showToast("Picture saved to " + pictureUrl);
        }
    }

    @Override
    public void onDoneCapturingAllPhotos(TreeMap<String, byte[]> picturesTaken) {
        if (picturesTaken != null && !picturesTaken.isEmpty()) {
            showToast("Done capturing all photos!");
            return;
        }
        showToast("No camera detected!");
    }
//    @TargetApi(Build.VERSION_CODES.M)
//    private void checkPermissions() {
//        final List<String> neededPermissions = new ArrayList<>();
//        for (final String permission : requiredPermissions) {
//            if (ContextCompat.checkSelfPermission(getApplicationContext(),
//                    permission) != PackageManager.PERMISSION_GRANTED) {
//                neededPermissions.add(permission);
//            }
//        }
//        if (!neededPermissions.isEmpty()) {
//            requestPermissions(neededPermissions.toArray(new String[]{}),
//                    MY_PERMISSIONS_REQUEST_ACCESS_CODE);
//        }
//    }
}
