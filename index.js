import React from 'react';
import {AppRegistry, StyleSheet, Text, View} from 'react-native';

class Help extends React.Component {
  render() {
    return (
      <View style={styles.container}>
        <Text style={styles.title}>FAQ</Text>
      </View>
    );
  }
}

class CurrencyInformations extends React.Component {
  render() {
    return (
      <View style={styles.container}>
        <Text style={styles.title}>Currency Informations</Text>
      </View>
    );
  }
}

var styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    backgroundColor: "#2962ff"
  },
  title: {
    fontSize: 20,
    textAlign: 'center',
    margin: 10,
    color: 'white'
  },
});


AppRegistry.registerComponent('CurrencyInformationsComponent', () => CurrencyInformations);
AppRegistry.registerComponent('HelpComponent', () => Help);