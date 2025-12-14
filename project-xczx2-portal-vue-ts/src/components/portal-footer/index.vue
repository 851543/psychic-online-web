<template>
  <footer>
    <div class="container">
      <div class="row">
        <div class="col-md-7">
          <div>
            <!--<h1 style="display: inline-block">学成网</h1>-->
            <img src="@/assets/img/logoIco.png" alt />
          </div>
          <div>通灵在线教育致力于普及中国最好的教育它与中国一流大学和机构合作提供在线课程</div>
        </div>
        <div class="col-md-5 row">
          <dl class="col-md-4">
            <dt>关于学成网</dt>
            <dd>管理团队</dd>
            <dd>工作机会</dd>
            <dd>客户服务</dd>
          </dl>
          <dl class="col-md-4">
            <dt>新手指南</dt>
            <dd>如何注册</dd>
            <dd>如何选课</dd>
          </dl>
          <dl class="col-md-4">
            <dt>合作伙伴</dt>
            <dd>合作机构</dd>
            <dd>合作导师</dd>
          </dl>
        </div>
      </div>
    </div>
  </footer>
</template>

<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";

@Component({
  name: "PortalFooter"
})
export default class extends Vue {}
</script>

<style lang="scss" scoped>
@import "index";
</style>