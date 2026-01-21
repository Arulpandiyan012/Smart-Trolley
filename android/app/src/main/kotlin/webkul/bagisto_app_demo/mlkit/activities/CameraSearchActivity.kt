/*
 * Copyright 2020 Google LLC. All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package webkul.bagisto_app_demo.mlkit.activities

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.hardware.Camera
import android.hardware.Camera.CameraInfo
import android.os.Bundle
import android.util.Log
import android.view.Menu
import android.view.View
import android.widget.*
import androidx.appcompat.app.AppCompatActivity
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.databinding.DataBindingUtil
import androidx.recyclerview.widget.LinearLayoutManager
// FIXED: Corrected imports to match your project namespace
import webkul.bagisto_app_demo.R
import webkul.bagisto_app_demo.databinding.ActivityCameraSearchBinding
import com.google.android.gms.common.annotation.KeepName
import com.google.mlkit.vision.label.ImageLabel
import com.google.mlkit.vision.label.defaults.ImageLabelerOptions
import com.google.mlkit.vision.text.Text
import webkul.bagisto_app_demo.mlkit.adapters.CameraSearchResultAdapter
import webkul.bagisto_app_demo.mlkit.customviews.CameraSource
import webkul.bagisto_app_demo.mlkit.labeldetector.LabelDetectorProcessor
import webkul.bagisto_app_demo.mlkit.textdetector.TextRecognitionProcessor
import java.io.IOException

/** Live preview demo for ML Kit APIs.  */
@KeepName
class CameraSearchActivity : AppCompatActivity(), ActivityCompat.OnRequestPermissionsResultCallback,
    CompoundButton.OnCheckedChangeListener {
    lateinit var mContentViewBinding: ActivityCameraSearchBinding
    private var cameraSource: CameraSource? = null
    private var resultNumberTv: TextView? = null
    private var displayAdapter: CameraSearchResultAdapter? = null
    private var selectedModel = TEXT_RECOGNITION
    lateinit var displayList: ArrayList<String>
    private var hasFlash = false

    companion object {
        const val CAMERA_SEARCH_HELPER = "searchHelper"
        const val TEXT_RECOGNITION = "Text Detection"
        const val IMAGE_LABELING = "Product Detection"
        private const val TAG = "LivePreviewActivity"
        private const val PERMISSION_REQUESTS = 1
        private fun isPermissionGranted(
            context: Context,
            permission: String?,
        ): Boolean {
            if (ContextCompat.checkSelfPermission(
                    context,
                    permission!!
                ) == PackageManager.PERMISSION_GRANTED
            ) {
                Log.i(TAG, "Permission granted: $permission")
                return true
            }
            Log.i(TAG, "Permission NOT granted: $permission")
            return false
        }

        var CAMERA_SELECTED_MODEL = "CAMERA_SELECTED_MODEL"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        mContentViewBinding = DataBindingUtil.setContentView(this, R.layout.activity_camera_search)
        displayList = ArrayList()

        if (intent.hasExtra(CAMERA_SELECTED_MODEL)) {
            selectedModel = intent.getStringExtra(CAMERA_SELECTED_MODEL)!!
        }
        
        // Permission check
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA)
            == PackageManager.PERMISSION_DENIED
        ) {
            ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.CAMERA), 200)
        }

        // Setup UI via Binding
        mContentViewBinding.resultsMessageTv.text = getString(R.string.x_results_found, displayList.size)
        mContentViewBinding.resultRv.layoutManager =
            LinearLayoutManager(this, LinearLayoutManager.VERTICAL, false)
        displayAdapter = CameraSearchResultAdapter(this, displayList)
        mContentViewBinding.resultRv.adapter = displayAdapter
        mContentViewBinding.resultRv.bringToFront()

        initSupportActionBar()
        cameraSwitchSetup()
        flashSetup()

        if (allPermissionsGranted()) {
            mContentViewBinding.previewView.stop()
            createCameraSource(selectedModel)
            startCameraSource()
        } else {
            runtimePermissions
        }
    }

    override fun onCreateOptionsMenu(menu: Menu): Boolean {
        return true
    }

    fun initSupportActionBar() {
        if (supportActionBar != null) {
            supportActionBar!!.setDisplayHomeAsUpEnabled(false)
            supportActionBar!!.setHomeButtonEnabled(false)
            supportActionBar!!.title = selectedModel
        }
    }

    private fun cameraSwitchSetup() {
        if (hasFrontCamera()) {
            mContentViewBinding.facingSwitch.setOnCheckedChangeListener { _, isChecked ->
                if (cameraSource != null) {
                    if (isChecked) {
                        mContentViewBinding.flashSwitch.visibility = View.GONE
                        cameraSource!!.setFacing(CameraSource.CAMERA_FACING_FRONT)
                    } else {
                        flashSetup()
                        cameraSource!!.setFacing(CameraSource.CAMERA_FACING_BACK)
                    }
                }
                mContentViewBinding.previewView.stop()
                displayList.clear()
                mContentViewBinding.resultRv.adapter?.notifyDataSetChanged()
                startCameraSource()
            }
        } else {
            mContentViewBinding.facingSwitch.isEnabled = false
            mContentViewBinding.facingSwitch.isChecked = false
            mContentViewBinding.facingSwitch.visibility = View.GONE
        }
    }

    private fun flashSetup() {
        hasFlash = applicationContext.packageManager.hasSystemFeature(PackageManager.FEATURE_CAMERA_FLASH)

        if (hasFlash) {
            mContentViewBinding.flashSwitch.visibility = View.VISIBLE
            mContentViewBinding.flashSwitch.setOnCheckedChangeListener { _, isChecked ->
                if (cameraSource != null) {
                    val camera = cameraSource!!.camera
                    if (camera != null) {
                        val parameters = camera.parameters
                        parameters.flashMode = if (isChecked) {
                            Camera.Parameters.FLASH_MODE_TORCH
                        } else {
                            Camera.Parameters.FLASH_MODE_OFF
                        }
                        camera.parameters = parameters
                    }
                } else {
                    Toast.makeText(
                        this@CameraSearchActivity,
                        getString(R.string.error_while_using_flash),
                        Toast.LENGTH_LONG
                    ).show()
                }
            }
        } else {
            mContentViewBinding.flashSwitch.visibility = View.GONE
        }
    }

    private fun hasFrontCamera(): Boolean {
        val cameraInfo = CameraInfo()
        val numberOfCameras = Camera.getNumberOfCameras()
        for (i in 0 until numberOfCameras) {
            Camera.getCameraInfo(i, cameraInfo)
            if (cameraInfo.facing == CameraInfo.CAMERA_FACING_FRONT) {
                return true
            }
        }
        return false
    }

    override fun onCheckedChanged(buttonView: CompoundButton, isChecked: Boolean) {
        if (cameraSource != null) {
            cameraSource?.setFacing(if (isChecked) CameraSource.CAMERA_FACING_FRONT else CameraSource.CAMERA_FACING_BACK)
        }
        mContentViewBinding.previewView.stop()
        startCameraSource()
    }

    private fun createCameraSource(model: String) {
        if (cameraSource == null) {
            cameraSource = CameraSource(this, mContentViewBinding.graphicOverlay)
        }
        try {
            when (model) {
                TEXT_RECOGNITION -> {
                    cameraSource!!.setMachineLearningFrameProcessor(TextRecognitionProcessor(this))
                    displayList.clear()
                }
                IMAGE_LABELING -> {
                    cameraSource!!.setMachineLearningFrameProcessor(
                        LabelDetectorProcessor(this, ImageLabelerOptions.DEFAULT_OPTIONS)
                    )
                    displayList.clear()
                }
                else -> Log.e("CameraActivity", "Unknown model: $model")
            }
        } catch (e: Exception) {
            Log.e("CameraActivity", "Can not create image processor: $model", e)
        }
    }

    private fun startCameraSource() {
        if (cameraSource != null) {
            try {
                mContentViewBinding.previewView.start(
                    cameraSource!!,
                    mContentViewBinding.graphicOverlay
                )
            } catch (e: IOException) {
                Log.e("CameraActivity", "Unable to start camera source.", e)
                cameraSource!!.release()
                cameraSource = null
            }
        }
    }

    public override fun onResume() {
        super.onResume()
        createCameraSource(selectedModel)
        startCameraSource()
    }

    override fun onPause() {
        super.onPause()
        mContentViewBinding.previewView.stop()
    }

    public override fun onDestroy() {
        super.onDestroy()
        cameraSource?.release()
    }

    private val requiredPermissions: Array<String?>
        get() = try {
            val info = this.packageManager.getPackageInfo(this.packageName, PackageManager.GET_PERMISSIONS)
            info.requestedPermissions ?: arrayOfNulls(0)
        } catch (e: Exception) {
            arrayOfNulls(0)
        }

    private fun allPermissionsGranted(): Boolean {
        for (permission in requiredPermissions) {
            if (!isPermissionGranted(this, permission)) return false
        }
        return true
    }

    private val runtimePermissions: Unit
        get() {
            val allNeededPermissions = requiredPermissions.filter { !isPermissionGranted(this, it) }
            if (allNeededPermissions.isNotEmpty()) {
                ActivityCompat.requestPermissions(this, allNeededPermissions.toTypedArray(), PERMISSION_REQUESTS)
            }
        }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        if (allPermissionsGranted()) {
            createCameraSource(selectedModel)
            startCameraSource()
        }
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
    }

    fun sendResultBack(position: Int) {
        val resultIntent = Intent()
        resultIntent.putExtra(CAMERA_SEARCH_HELPER, displayList[position])
        this.setResult(RESULT_OK, resultIntent)
        this.finish()
    }

    var contentChange = true
    fun updateSpinnerFromTextResults(textResults: Text) {
        val blocks: List<Text.TextBlock> = textResults.textBlocks
        for (eachBlock in blocks) {
            for (eachLine in eachBlock.lines) {
                for (eachElement in eachLine.elements) {
                    if (!displayList.contains(eachElement.text) && displayList.size <= 9) {
                        displayList.add(eachElement.text)
                        contentChange = true
                    }
                }
            }
        }
        if (contentChange) {
            mContentViewBinding.resultsMessageTv.text = getString(R.string.x_results_found, displayList.size)
            mContentViewBinding.resultRv.adapter?.notifyDataSetChanged()
            contentChange = false
        }
    }

    fun updateSpinnerFromResults(labelList: List<ImageLabel>) {
        for (visionLabel in labelList) {
            if (!displayList.contains(visionLabel.text) && visionLabel.confidence > 0.5f && displayList.size <= 9) {
                displayList.add(visionLabel.text)
                contentChange = true
            }
        }
        if (contentChange) {
            mContentViewBinding.resultsMessageTv.text = getString(R.string.x_results_found, displayList.size)
            mContentViewBinding.resultRv.adapter?.notifyDataSetChanged()
            contentChange = false
        }
    }
}