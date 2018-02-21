/**
 * Copyright 2017 Erik Jhordan Rey.
 * <p>
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * <p>
 * http://www.apache.org/licenses/LICENSE-2.0
 * <p>
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package erikjhordanrey.android_kotlin_devises.view

import android.os.Bundle
import android.support.design.widget.BottomNavigationView
import android.support.v4.app.Fragment
import android.support.v7.app.AppCompatActivity
import android.view.MenuItem
import erikjhordanrey.android_kotlin_devises.R
import kotlinx.android.synthetic.main.activity_main.*
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.view.KeyEvent
import android.widget.Toast
import com.facebook.react.modules.core.DefaultHardwareBackBtnHandler
import com.hudl.oss.react.fragment.ReactFragment



class NavigationActivity : AppCompatActivity(), BottomNavigationView.OnNavigationItemSelectedListener, DefaultHardwareBackBtnHandler {


  val OVERLAY_PERMISSION_REQ_CODE = 1
  val HELP_COMPONENT = "HelpComponent"

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
      if (!Settings.canDrawOverlays(this)) {
        val intent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                Uri.parse("package:" + packageName))
        startActivityForResult(intent, OVERLAY_PERMISSION_REQ_CODE)
      }
    }

    setContentView(R.layout.activity_main)
    if (savedInstanceState == null) {
      replaceFragment(CurrencyFragment.newInstance())
    }

    initNavigation()
  }

  override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent) {
    if (requestCode == OVERLAY_PERMISSION_REQ_CODE
            && Build.VERSION.SDK_INT >= Build.VERSION_CODES.M
            && !Settings.canDrawOverlays(this)) {
      Toast.makeText(this, getString(R.string.permission_system_not_granted), Toast.LENGTH_LONG)
    }
  }

  override fun onNavigationItemSelected(item: MenuItem): Boolean {
    when (item.itemId) {
      R.id.navigation_home -> {
        replaceFragment(CurrencyFragment.newInstance())
        return true
      }
      R.id.navigation_dashboard -> {
        replaceFragment(AboutFragment.newInstance())
        return true
      }
      R.id.navigation_help -> {
        val reactFragment = ReactFragment.Builder(HELP_COMPONENT).build()
        replaceFragment(reactFragment)
        return true
      }
    }
    return false
  }

  private fun initNavigation() {
    navigation.setOnNavigationItemSelectedListener(this)
  }

  private fun replaceFragment(fragment: Fragment) {
    supportFragmentManager.beginTransaction()
            .replace(R.id.content, fragment)
            .commit()
  }

  override fun invokeDefaultOnBackPressed() {
    super.onBackPressed()
  }

  /**
   * Forward onKeyUp events to the ReactFragment in order to handle double tap reloads
   * and dev menus
   *
   * @param keyCode
   * @param event
   * @return true if event was handled
   */
  override fun onKeyUp(keyCode: Int, event: KeyEvent): Boolean {
    var handled = false
    val activeFragment = supportFragmentManager.findFragmentById(R.id.content)
    if (activeFragment is ReactFragment) {
      handled = activeFragment.onKeyUp(keyCode, event)
    }
    return handled || super.onKeyUp(keyCode, event)
  }

}
