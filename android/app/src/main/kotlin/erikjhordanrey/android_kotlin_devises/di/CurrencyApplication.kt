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

package erikjhordanrey.android_kotlin_devises.di

import android.app.Application
import com.facebook.react.ReactApplication
import com.facebook.react.ReactNativeHost
import com.facebook.soloader.SoLoader
import com.facebook.react.shell.MainReactPackage
import com.facebook.react.ReactPackage
import erikjhordanrey.android_kotlin_devises.BuildConfig
import java.util.*



class CurrencyApplication : Application(), ReactApplication {

  private val mReactNativeHost = object : ReactNativeHost(this) {
    override fun getUseDeveloperSupport(): Boolean {
      return BuildConfig.DEBUG
    }

    override fun getPackages(): List<ReactPackage> {
      return Arrays.asList(
              MainReactPackage()
      )
    }

    override fun getJSMainModuleName(): String {
      return "index"
    }
  }

  companion object {
    lateinit var appComponent: AppComponent
  }

  override fun onCreate() {
    super.onCreate()
    initializeDagger()
    SoLoader.init(this, false)
  }

  fun initializeDagger() {
    appComponent = DaggerAppComponent.builder()
        .appModule(AppModule(this))
        .roomModule(RoomModule())
        .remoteModule(RemoteModule()).build()
  }

  override fun getReactNativeHost(): ReactNativeHost {
    return mReactNativeHost
  }
}

