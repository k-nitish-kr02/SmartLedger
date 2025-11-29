import {View, StyleSheet, Alert} from 'react-native';
import React, {useEffect, useState} from 'react';
import CustomText from '../components/CustomText';
import CustomBox from '../components/CustomBox';
import {GestureHandlerRootView, TextInput} from 'react-native-gesture-handler';
import {Button} from '@gluestack-ui/themed';
import ApiService from '../api/ApiService';
import {NativeStackNavigationProp} from '@react-navigation/native-stack';

// Import RootStackParamList from App.tsx where Login and SignUp are defined
type RootStackParamList = {
  Login: undefined;
  SignUp: undefined;
  Home: undefined;
  Profile: undefined;
};

type LoginScreenNavigationProp = NativeStackNavigationProp<RootStackParamList, 'Login'>;

interface LoginProps {
  navigation: LoginScreenNavigationProp;
}

const Login = ({navigation}: LoginProps) => {
  const [userName, setUserName] = useState('');
  const [password, setPassword] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [loggedIn, setLoggedIn] = useState(false);

  const gotoHomePageWithLogin = async () => {
    if (!userName.trim() || !password.trim()) {
      Alert.alert('Error', 'Please enter both username and password');
      return;
    }

    setIsLoading(true);
    try {
      const response = await ApiService.login(userName, password);
      
      if (response.error) {
        Alert.alert('Login Failed', response.error);
      } else if (response.data) {
        navigation.navigate('Home');
      }
    } catch (error) {
      Alert.alert('Error', 'An unexpected error occurred. Please try again.');
      console.error('Login error:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const gotoSignup = () => {
    navigation.navigate('SignUp');
  };

  useEffect(() => {
    const checkLoginStatus = async () => {
      try {
        const isLoggedIn = await ApiService.isLoggedIn();
        setLoggedIn(isLoggedIn);
        if (isLoggedIn) {
          navigation.navigate('Home');
        }
      } catch (error) {
        console.error('Error checking login status:', error);
        setLoggedIn(false);
      }
    };
    checkLoginStatus();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  return (
    <GestureHandlerRootView style={{flex: 1}}>
      <View style={styles.loginContainer}>
        <CustomBox style={loginBox}>
          <CustomText style={styles.heading}>Login</CustomText>
          <TextInput
            placeholder="User Name"
            value={userName}
            onChangeText={text => setUserName(text)}
            style={styles.textInput}
            placeholderTextColor="#888"
          />
          <TextInput
            placeholder="Password"
            value={password}
            onChangeText={text => setPassword(text)}
            style={styles.textInput}
            placeholderTextColor="#888"
            secureTextEntry
          />
        </CustomBox>
        <Button 
          onPressIn={() => gotoHomePageWithLogin()} 
          style={styles.button}
          isDisabled={isLoading}
        >
          <CustomBox style={buttonBox}>
            <CustomText style={{textAlign: 'center'}}>
              {isLoading ? 'Logging in...' : 'Submit'}
            </CustomText>
          </CustomBox>
        </Button>
        <Button onPressIn={() => gotoSignup()} style={styles.button}>
          <CustomBox style={buttonBox}>
            <CustomText style={{textAlign: 'center'}}>Goto Signup</CustomText>
          </CustomBox>
        </Button>
      </View>
    </GestureHandlerRootView>
  );
};

export default Login;

const styles = StyleSheet.create({
  loginContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 20,
  },
  button: {
    marginTop: 20,
    width: '30%',
  },
  heading: {
    fontSize: 24,
    fontWeight: 'bold',
    marginBottom: 20,
  },
  textInput: {
    backgroundColor: '#f0f0f0',
    borderRadius: 5,
    padding: 10,
    marginBottom: 10,
    width: '100%',
    color: 'black',
  },
});

const loginBox = {
  mainBox: {
    backgroundColor: '#fff',
    borderColor: 'black',
    borderWidth: 1,
    borderRadius: 10,
    padding: 20,
  },
  shadowBox: {
    backgroundColor: 'gray',
    borderRadius: 10,
  },
};

const buttonBox = {
  mainBox: {
    backgroundColor: '#fff',
    borderColor: 'black',
    borderWidth: 1,
    borderRadius: 10,
    padding: 10,
  },
  shadowBox: {
    backgroundColor: 'gray',
    borderRadius: 10,
  },
};
