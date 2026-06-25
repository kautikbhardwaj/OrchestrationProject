import React, { useEffect, useState } from "react";
import axios from "axios";

function Home() {
  const [message, setMessage] = useState("");
  const [profile, setProfile] = useState([]);
  const helloApi = process.env.REACT_APP_HELLO_API_URL || "/api/hello";
  const profileApi = process.env.REACT_APP_PROFILE_API_URL || "/api/profile";

  useEffect(() => {
    axios
      .get(helloApi)
      .then((response) => {
        setMessage(response.data.msg);
      })
      .catch((error) => console.error("Error fetching data:", error));
  }, [helloApi]);

  useEffect(() => {
    axios
      .get(`${profileApi}/fetchUser`)
      .then((response) => {
        setProfile(response.data);
        
      })
      .catch((error) => console.error("Error fetching data:", error));
  },[profileApi]);

  

  return (
    <div className="App">
      <h1>{message}</h1>
      <div>
        <h2>Profile</h2>
        {
        profile.map((user) => {
            console.log('user', user)
          return (
            <div key={user._id || `${user.name}-${user.age}`}>
              <h3>Name: {user.name}</h3>
              <h3>Age: {user.age}</h3>
            </div>
          );
        })}
      </div>
    </div>
  );
}

export default Home;
