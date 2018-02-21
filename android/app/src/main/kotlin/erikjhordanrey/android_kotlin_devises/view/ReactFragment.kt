/*
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package com.hudl.oss.react.fragment

import android.annotation.TargetApi
import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.support.v4.app.Fragment
import android.view.KeyEvent
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Toast

import com.facebook.infer.annotation.Assertions
import com.facebook.react.ReactApplication
import com.facebook.react.ReactNativeHost
import com.facebook.react.ReactRootView
import com.facebook.react.common.LifecycleState
import com.facebook.react.devsupport.DoubleTapReloadRecognizer
import com.facebook.react.modules.core.DefaultHardwareBackBtnHandler
import com.facebook.react.modules.core.PermissionAwareActivity
import com.facebook.react.modules.core.PermissionListener


/**
 * A [Fragment] which loads a React Native Component from your React Native JS Bundle.
 *
 *
 * NOTE: You can achieve the same behaviour with an Activity by extending
 * [com.facebook.react.ReactActivity]
 */
class ReactFragment : Fragment(), PermissionAwareActivity {

    private var mComponentName: String? = null
    private var mLaunchOptions: Bundle? = null

    private var mReactRootView: ReactRootView? = null

    private var mDoubleTapReloadRecognizer: DoubleTapReloadRecognizer? = null

    private var mPermissionListener: PermissionListener? = null

    // endregion

    /**
     * Get the [ReactNativeHost] used by this app. By default, assumes
     * [Activity.getApplication] is an instance of [ReactApplication] and calls
     * [ReactApplication.getReactNativeHost]. Override this method if your application class
     * does not implement `ReactApplication` or you simply have a different mechanism for
     * storing a `ReactNativeHost`, e.g. as a static field somewhere.
     */
    protected val reactNativeHost: ReactNativeHost
        get() = (activity!!.application as ReactApplication).getReactNativeHost()

    // region Lifecycle

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (arguments != null) {
            mComponentName = arguments!!.getString(ARG_COMPONENT_NAME)
            mLaunchOptions = arguments!!.getBundle(ARG_LAUNCH_OPTIONS)
        }
        if (mComponentName == null) {
            throw IllegalStateException("Cannot loadApp if component name is null")
        }
        mDoubleTapReloadRecognizer = DoubleTapReloadRecognizer()
    }

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?,
                              savedInstanceState: Bundle?): View? {
        var needToEnableDevMenu = false

        if (reactNativeHost.getUseDeveloperSupport()
                && Build.VERSION.SDK_INT >= Build.VERSION_CODES.M
                && !Settings.canDrawOverlays(context)) {
            // Get permission to show redbox in dev builds.
            needToEnableDevMenu = true
            val serviceIntent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:" + context!!.packageName))
            Toast.makeText(context, REDBOX_PERMISSION_MESSAGE, Toast.LENGTH_LONG).show()
            startActivityForResult(serviceIntent, REQUEST_OVERLAY_CODE)
        }

        mReactRootView = ReactRootView(context)

        if (!needToEnableDevMenu) {
            mReactRootView!!.startReactApplication(
                    reactNativeHost.getReactInstanceManager(),
                    mComponentName,
                    mLaunchOptions)
        }

        return mReactRootView
    }

    override fun onResume() {
        super.onResume()
        if (reactNativeHost.hasInstance()) {
            reactNativeHost.getReactInstanceManager().onHostResume(activity, activity as DefaultHardwareBackBtnHandler?)
        }
    }

    override fun onPause() {
        super.onPause()
        if (reactNativeHost.hasInstance()) {
            reactNativeHost.getReactInstanceManager().onHostPause(activity)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        if (mReactRootView != null) {
            mReactRootView!!.unmountReactApplication()
            mReactRootView = null
        }
        if (reactNativeHost.hasInstance()) {
            val reactInstanceMgr = reactNativeHost.getReactInstanceManager()
            reactInstanceMgr.onHostDestroy(activity)

            // onDestroy may be called on a ReactFragment after another ReactFragment has been
            // created and resumed with the same React Instance Manager. Make sure we only clean up
            // host's React Instance Manager if no other React Fragment is actively using it.
            if (reactInstanceMgr.getLifecycleState() !== LifecycleState.RESUMED) {
                reactNativeHost.clear()
            }
        }
    }

    // endregion

    /**
     * This currently only checks to see if we've enabled the permission to draw over other apps.
     * This is only used in debug/developer mode and is otherwise not used.
     *
     * @param requestCode Code that requested the activity
     * @param resultCode  Code which describes the result
     * @param data        Any data passed from the activity
     */
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == REQUEST_OVERLAY_CODE
                && Build.VERSION.SDK_INT >= Build.VERSION_CODES.M
                && Settings.canDrawOverlays(context)) {
            mReactRootView!!.startReactApplication(
                    reactNativeHost.getReactInstanceManager(),
                    mComponentName,
                    mLaunchOptions)
            Toast.makeText(context, REDBOX_PERMISSION_GRANTED_MESSAGE, Toast.LENGTH_LONG).show()
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (mPermissionListener != null && mPermissionListener!!.onRequestPermissionsResult(requestCode, permissions, grantResults)) {
            mPermissionListener = null
        }
    }

    // region PermissionAwareActivity

    override fun checkPermission(permission: String, pid: Int, uid: Int): Int {
        return activity!!.checkPermission(permission, pid, uid)
    }

    @TargetApi(Build.VERSION_CODES.M)
    override fun checkSelfPermission(permission: String): Int {
        return activity!!.checkSelfPermission(permission)
    }

    @TargetApi(Build.VERSION_CODES.M)
    override fun requestPermissions(permissions: Array<String>, requestCode: Int, listener: PermissionListener) {
        mPermissionListener = listener
        requestPermissions(permissions, requestCode)
    }

    // endregion

    // region Helpers

    /**
     * Helper to forward hardware back presses to our React Native Host
     */
    fun onBackPressed() {
        if (reactNativeHost.hasInstance()) {
            reactNativeHost.getReactInstanceManager().onBackPressed()
        }
    }

    /**
     * Helper to forward onKeyUp commands from our host Activity.
     * This allows ReactFragment to handle double tap reloads and dev menus
     *
     * @param keyCode keyCode
     * @param event   event
     * @return true if we handled onKeyUp
     */
    fun onKeyUp(keyCode: Int, event: KeyEvent): Boolean {
        var handled = false
        if (reactNativeHost.getUseDeveloperSupport() && reactNativeHost.hasInstance()) {
            if (keyCode == KeyEvent.KEYCODE_MENU) {
                reactNativeHost.getReactInstanceManager().showDevOptionsDialog()
                handled = true
            }
            val didDoubleTapR = Assertions.assertNotNull(mDoubleTapReloadRecognizer).didDoubleTapR(keyCode, activity!!.currentFocus)
            if (didDoubleTapR) {
                reactNativeHost.getReactInstanceManager().getDevSupportManager().handleReloadJS()
                handled = true
            }
        }
        return handled
    }

    /**
     * Builder class to help instantiate a [ReactFragment]
     */
    class Builder
    /**
     * Returns new Builder for creating a [ReactFragment]
     *
     * @param componentName The name of your React Native component
     */
    (private val mComponentName: String) {
        private var mLaunchOptions: Bundle? = null

        /**
         * Set the Launch Options for our React Native instance.
         *
         * @param launchOptions launchOptions
         * @return Builder
         */
        fun setLaunchOptions(launchOptions: Bundle): Builder {
            mLaunchOptions = launchOptions
            return this
        }

        fun build(): ReactFragment {
            return ReactFragment.newInstance(mComponentName, mLaunchOptions)
        }

    }

    companion object {

        val REQUEST_OVERLAY_CODE = 1111
        val ARG_COMPONENT_NAME = "arg_component_name"
        val ARG_LAUNCH_OPTIONS = "arg_launch_options"

        private val REDBOX_PERMISSION_MESSAGE = "Overlay permissions need to be granted in order for react native apps to run in dev mode."
        private val REDBOX_PERMISSION_GRANTED_MESSAGE = "Overlay permissions have been granted."

        /**
         * @param componentName The name of the react native component
         * @param launchOptions Optional launch options
         * @return A new instance of fragment ReactFragment.
         */
        private fun newInstance(componentName: String, launchOptions: Bundle?): ReactFragment {
            val fragment = ReactFragment()
            val args = Bundle()
            args.putString(ARG_COMPONENT_NAME, componentName)
            args.putBundle(ARG_LAUNCH_OPTIONS, launchOptions)
            fragment.arguments = args
            return fragment
        }
    }
}