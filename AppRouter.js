import { NavigationContainer } from '@react-navigation/native';
import * as React from 'react';
import { createStackNavigator } from '@react-navigation/stack';
import { View,Text, Button } from 'react-native';
const Stack = createStackNavigator();
const HomeScreen = ({ navigation }) => {
    return (
      <Button
        title="Go to Jane's profile"
        onPress={() =>
          navigation.navigate('Profile', { name: 'Jane' })
        }
      />
    );
  };
  const ProfileScreen = () => {
    return <Text>This is Jane's profile</Text>;
  };

const AppRouter = props => {
    return <NavigationContainer>
        <Stack.Navigator>
            {/* <Stack.Screen
                name="Home"
                component={HomeScreen}
                options={{ title: 'Welcome' }}
            /> */}
            <Stack.Screen name="Profile" component={ProfileScreen} />
        </Stack.Navigator>
    </NavigationContainer>
}
export default AppRouter;