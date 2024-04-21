import { createRouter, createWebHistory } from "vue-router";
import LandingView from "../views/LandingView.vue";

const routes = [
  {
    path: "/",
    name: "landingview",
    component: LandingView,
  },
  {
    path: "/home",
    name: "homeview",
    // route level code-splitting
    // this generates a separate chunk (about.[hash].js) for this route
    // which is lazy-loaded when the route is visited.
    component: () =>
      import(/* webpackChunkName: "about" */ "../views/HomeView.vue"),
  },
];

const router = createRouter({
  history: createWebHistory(process.env.BASE_URL),
  routes,
});

export default router;
