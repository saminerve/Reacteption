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

import android.arch.lifecycle.Lifecycle.Event.ON_DESTROY
import android.arch.lifecycle.LifecycleObserver
import android.arch.lifecycle.LiveData
import android.arch.lifecycle.MutableLiveData
import android.arch.lifecycle.OnLifecycleEvent
import android.arch.lifecycle.ViewModel
import android.util.Log
import erikjhordanrey.android_kotlin_devises.data.repository.CurrencyRepository
import erikjhordanrey.android_kotlin_devises.di.CurrencyApplication
import erikjhordanrey.android_kotlin_devises.domain.AvailableExchange
import erikjhordanrey.android_kotlin_devises.domain.Currency
import io.reactivex.Completable
import io.reactivex.CompletableObserver
import io.reactivex.android.schedulers.AndroidSchedulers
import io.reactivex.annotations.NonNull
import io.reactivex.disposables.CompositeDisposable
import io.reactivex.disposables.Disposable
import io.reactivex.schedulers.Schedulers
import javax.inject.Inject

class CurrencyViewModel : ViewModel(), LifecycleObserver {

  @Inject lateinit var currencyRepository: CurrencyRepository

  private val compositeDisposable = CompositeDisposable()
  private var liveCurrencyData: LiveData<List<Currency>>? = null
  private var liveAvailableExchange: LiveData<AvailableExchange>? = null

  init {
    initializeDagger()
  }


  fun getAvailableExchange(currencies: String): LiveData<AvailableExchange>? {
    liveAvailableExchange = null
    liveAvailableExchange = MutableLiveData<AvailableExchange>()
    liveAvailableExchange = currencyRepository.getAvailableExchange(currencies)
    return liveAvailableExchange
  }


  fun loadCurrencyList(): LiveData<List<Currency>>? {
    if (liveCurrencyData == null) {
      liveCurrencyData = MutableLiveData<List<Currency>>()
      liveCurrencyData = currencyRepository.getCurrencyList()
    }
    return liveCurrencyData
  }

  fun initLocalCurrencies() {
    val disposable = currencyRepository.getTotalCurrencies()
        .subscribeOn(Schedulers.io())
        .observeOn(AndroidSchedulers.mainThread())
        .subscribe {
          if (isRoomEmpty(it)) {
            populate()
          } else {
            Log.i(CurrencyRepository::class.java.simpleName, "DataSource has been already Populated")
          }
        }
    compositeDisposable.add(disposable)
  }

  @OnLifecycleEvent(ON_DESTROY)
  fun unSubscribeViewModel() {
    for (disposable in currencyRepository.allCompositeDisposable) {
      compositeDisposable.addAll(disposable)
    }
    compositeDisposable.clear()
  }

  private fun isRoomEmpty(currenciesTotal: Int) = currenciesTotal == 0

  private fun populate() {
    Completable.fromAction { currencyRepository.addCurrencies() }
        .subscribeOn(Schedulers.io())
        .observeOn(AndroidSchedulers.mainThread())
        .subscribe(object : CompletableObserver {
          override fun onSubscribe(@NonNull d: Disposable) {
            compositeDisposable.add(d)
          }

          override fun onComplete() {
            Log.i(CurrencyRepository::class.java.simpleName, "DataSource has been Populated")

          }

          override fun onError(@NonNull e: Throwable) {
            e.printStackTrace()
            Log.e(CurrencyRepository::class.java.simpleName, "DataSource hasn't been Populated")
          }
        })
  }

  override fun onCleared() {
    unSubscribeViewModel()
    super.onCleared()
  }


  private fun initializeDagger() = CurrencyApplication.appComponent.inject(this)

}


