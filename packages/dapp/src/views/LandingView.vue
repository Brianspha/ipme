<template>
  <main id="app">
    <section class="intro">
      <div
        class="introDescription"
        data-aos="zoom-in"
        data-aos-duration="1500"
        data-aos-delay="500"
      >
        A new way
        <br>
        <p>of managing Intelectual Property</p>
        <button class="button" @click="$router.push({path: '/home'});">
          Launch DApp
        </button>
      </div>
      <img
        class="introImage"
        src="https://res.cloudinary.com/dsderm9xw/image/upload/v1622028117/3D%20Illustrations/3d-illustration4_usckww.png"
        alt="3d illustration of boy with a flag"
      >
    </section>

    <section class="guide1">
      <img
        class="guide1Image"
        src="https://res.cloudinary.com/dsderm9xw/image/upload/v1622028085/3D%20Illustrations/3d-illustration2_ykuua3.png"
        alt="3d illustration of boy sitting with legs crossed"
        data-aos="slide-down"
        data-aos-ease="ease"
        data-aos-duration="1500"
        data-aos-delay="500"
      >
      <div
        class="guide1Description"
        data-aos="slide-up"
        data-aos-ease="ease"
        data-aos-duration="1500"
        data-aos-delay="1000"
      >
        <h1>
          Distribute your <br>
          IPs
        </h1>
        <div>
          Leveraging the Story Protocol
          <br>
          and Sign Protocol, Mint IPs and
          <br>
          Watch them earn and own other IPs
        </div>
      </div>
    </section>
  </main>
</template>

<!-- Use preprocessors via the lang attribute! e.g. <style lang="scss"> -->
<style>
* {
  margin: 0;
  padding: 0;
}

.intro {
  display: flex;
  background: #fff3e2;
  justify-content: space-evenly;
  padding-top: 80px;
  height: 500px;
}
.introDescription {
  font-size: 30px;
  color: #632b2b;
  padding-top: 120px;
}
.introDescription p {
  font-size: 60px;
  color: #632b2b;
  font-weight: 900;
}

.guide1 {
  display: flex;
  background: #ffd4a9;
  justify-content: space-evenly;
  padding-top: 80px;
  height: 500px;
  overflow: hidden;
}
.guide1Description h1 {
  font-size: 48px;
  color: #632b2b;
  padding: 120px 0px 20px 0px;
}
.guide1Description div {
  background: #fff3e2;
  color: #632b2b;
  font-size: 20px;
  padding: 10px;
  border-radius: 10px;
}

.guide2 {
  display: flex;
  background: #fff3e2;
  justify-content: space-evenly;
  padding-top: 80px;
  height: 500px;
  overflow: hidden;
}
.guide2Description h1 {
  font-size: 48px;
  color: #632b2b;
  padding: 120px 0px 20px 0px;
}
.guide2Description div {
  background: #ffd4a9;
  color: #632b2b;
  font-size: 20px;
  padding: 10px;
  border-radius: 10px;
}

footer {
  background: #ffd4a9;
  color: #632b2b;
  padding: 10px;
  text-align: right;
  font-weight: 900;
}

/* responsiveness */
@media screen and (max-width: 500px) {
  .intro {
    display: block;
    padding-top: 10px;
    height: auto;
  }
  .introImage {
    width: 100%;
  }
  .introDescription {
    padding: 30px 0px 0px 20px;
  }

  .guide1 {
    display: block;
    padding-top: 10px;
    height: auto;
  }
  .guide1Image {
    width: 100%;
  }
  .guide1Description {
    padding: 20px;
  }
  .guide1Description h1 {
    padding: 30px 0px;
  }

  .guide2 {
    display: block;
    padding-top: 10px;
    height: auto;
  }
  .guide2Image {
    width: 100%;
  }
  .guide2Description {
    padding: 20px;
  }
  .guide2Description h1 {
    padding: 30px 0px;
  }
}
.button {
  display: inline-block;
  padding: 15px 25px;
  font-size: 24px;
  cursor: pointer;
  text-align: center;
  text-decoration: none;
  outline: none;
  color: #fff;
  background-color: #ffd4a9;
  border: none;
  border-radius: 15px;
  box-shadow: 0 9px #999;
}

.button:hover {
  background-color: #632b2b;
  color: black;
}

.button:active {
  background-color: #632b2b;
  box-shadow: 0 5px #666;
  transform: translateY(4px);
}
</style>

<script>
import AOS from "aos";
export default {
  mounted() {
    AOS.init();
  },
};
</script>
